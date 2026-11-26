create table private.code_login_windows (
  login_hash text not null check (login_hash ~ '^[0-9a-f]{64}$'),
  window_start timestamptz not null,
  attempts integer not null check (attempts between 1 and 12),
  primary key (login_hash, window_start)
);

create index code_login_windows_expiration_idx
  on private.code_login_windows (window_start);
revoke all on private.code_login_windows from public, anon, authenticated;

create function public.consume_code_login_attempt(login_hash text)
returns boolean language sql volatile security invoker set search_path = ''
as $$
  with allowed as (
    insert into private.code_login_windows as windows (login_hash, window_start, attempts)
    values ($1, pg_catalog.date_bin('5 minutes', now(), '2000-01-01 UTC'::timestamptz), 1)
    on conflict on constraint code_login_windows_pkey do update
      set attempts = windows.attempts + 1
      where windows.attempts < 12
    returning 1
  )
  select exists (select 1 from allowed);
$$;
revoke all on function public.consume_code_login_attempt(text) from public, anon, authenticated;
grant usage on schema private to service_role;
grant select, insert, update on private.code_login_windows to service_role;
grant execute on function public.consume_code_login_attempt(text) to service_role;

create table private.admin_account_audit (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid,
  target_id uuid not null,
  previous_role text,
  new_role text not null,
  previous_active boolean,
  new_active boolean
);
create index admin_account_audit_occurred_idx on private.admin_account_audit (occurred_at);
revoke all on private.admin_account_audit from public, anon, authenticated;

create function private.record_admin_account_change()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.role::text <> 'admin' then return new; end if;
    insert into private.admin_account_audit (actor_id, target_id, new_role, new_active)
      values (auth.uid(), new.id, new.role::text, new.is_active);
  elsif new.role is not distinct from old.role and new.is_active is not distinct from old.is_active then
    return new;
  else
    insert into private.admin_account_audit
      (actor_id, target_id, previous_role, new_role, previous_active, new_active)
      values (auth.uid(), new.id, old.role::text, new.role::text, old.is_active, new.is_active);
  end if;
  if new.role::text = 'admin' then
    raise log 'uth_admin_access_changed';
  elsif tg_op = 'UPDATE' and old.role::text = 'admin' then
    raise log 'uth_admin_access_changed';
  end if;
  return new;
end;
$$;
revoke all on function private.record_admin_account_change() from public, anon, authenticated;
create trigger audit_admin_account_change
  after insert or update of role, is_active on public.profiles
  for each row execute function private.record_admin_account_change();

create extension if not exists pg_cron;
select cron.schedule(
  'uth-expire-code-login-windows',
  '*/5 * * * *',
  $job$
    do $monitor$
    declare
      finished_window timestamptz := date_bin('5 minutes', now(), '2000-01-01 UTC'::timestamptz) - interval '5 minutes';
      limited_count bigint;
    begin
      select count(*) into limited_count from private.code_login_windows
        where window_start = finished_window and attempts = 12;
      if limited_count >= 10 then
        raise log 'uth_code_login_limit_saturation: % identifiers in five minutes', limited_count;
      end if;
      delete from private.code_login_windows where window_start < now() - interval '15 minutes';
    end;
    $monitor$;
  $job$
);
