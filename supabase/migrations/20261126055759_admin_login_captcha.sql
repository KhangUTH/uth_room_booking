create table private.admin_login_failures (
  login_hash text primary key check (login_hash ~ '^[0-9a-f]{64}$'),
  failures integer not null check (failures between 1 and 5),
  expires_at timestamptz not null
);

create table private.admin_verified_login_sessions (
  session_id uuid primary key references auth.sessions(id) on delete cascade
);

revoke all on private.admin_login_failures, private.admin_verified_login_sessions
  from public, anon, authenticated;

create function public.admin_login_protection(
  login_hash text, operation text, verified_session uuid default null, captcha_verified boolean default false
)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare
  failures_so_far integer;
begin
  if login_hash is null or login_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid login identifier' using errcode = '22023';
  end if;
  -- Serialize changes for an identifier and recheck before accepting logins.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(login_hash, 8317));
  if operation = 'failure' then
    insert into private.admin_login_failures as current_failure (login_hash, failures, expires_at)
      values (login_hash, 1, now() + interval '15 minutes')
      on conflict on constraint admin_login_failures_pkey do update
        set failures = case when current_failure.expires_at <= now() then 1
          else least(current_failure.failures + 1, 5) end,
          expires_at = excluded.expires_at
      returning failures into failures_so_far;
    return failures_so_far >= 5;
  end if;
  select f.failures into failures_so_far from private.admin_login_failures f
    where f.login_hash = $1 and f.expires_at > now();
  if operation = 'check' then return coalesce(failures_so_far >= 5, false); end if;
  if operation = 'success' and verified_session is not null then
    if failures_so_far >= 5 and captcha_verified is not true then return false; end if;
    insert into private.admin_verified_login_sessions (session_id) values (verified_session)
      on conflict do nothing;
    delete from private.admin_login_failures f where f.login_hash = $1;
    return true;
  end if;
  raise exception 'Invalid login protection operation' using errcode = '22023';
end;
$$;

revoke all on function public.admin_login_protection(text, text, uuid, boolean) from public, anon, authenticated;
grant execute on function public.admin_login_protection(text, text, uuid, boolean) to service_role;

alter function public.admin_web_session(text, uuid) set schema private;
revoke all on function private.admin_web_session(text, uuid) from public, anon, authenticated;

create function public.admin_web_session(action text, browser_id uuid default null)
returns text language plpgsql security definer set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  current_session uuid := (auth.jwt() ->> 'session_id')::uuid;
begin
  if action in ('claim', 'switch')
    and not exists (select 1 from private.admin_verified_login_sessions where session_id = current_session)
    and not exists (
      select 1 from private.admin_web_sessions
      where session_id = current_session and user_id = caller and revoked_at is null
    ) then
    return 'revoked';
  end if;
  return private.admin_web_session(action, browser_id);
end;
$$;

revoke all on function public.admin_web_session(text, uuid) from public, anon;
grant execute on function public.admin_web_session(text, uuid) to authenticated;

select cron.schedule('uth-expire-admin-login-failures', '*/10 * * * *',
  $job$delete from private.admin_login_failures where expires_at <= now()$job$);
