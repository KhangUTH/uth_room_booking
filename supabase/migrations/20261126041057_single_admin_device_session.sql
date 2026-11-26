create table private.admin_web_sessions (
  session_id uuid primary key references auth.sessions(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  device_id uuid not null,
  revoked_at timestamptz
);
create unique index admin_web_sessions_one_active
  on private.admin_web_sessions(user_id) where revoked_at is null;
revoke all on private.admin_web_sessions from public, anon, authenticated;

create function public.admin_web_session(action text, browser_id uuid default null)
returns text language plpgsql security definer set search_path = ''
as $$
declare
  caller uuid := auth.uid();
  current_session uuid := (auth.jwt() ->> 'session_id')::uuid;
  existing private.admin_web_sessions%rowtype;
begin
  if action is null or action not in ('status', 'claim', 'switch', 'release')
    or (action in ('claim', 'switch') and browser_id is null) then
    raise exception 'Invalid admin session operation' using errcode = '22023';
  end if;
  if caller is null or current_session is null then return 'revoked'; end if;

  -- Serialize competing claims and switches for the same admin.
  if action <> 'status' then
    perform 1 from public.profiles where id = caller and role = 'admin' and is_active for update;
    if not found then return 'revoked'; end if;
  end if;
  if not exists (select 1 from public.profiles where id = caller and role = 'admin' and is_active)
    or not exists (select 1 from auth.sessions where id = current_session and user_id = caller)
    or exists (select 1 from private.admin_web_sessions where session_id = current_session and revoked_at is not null)
    then return 'revoked'; end if;

  select * into existing from private.admin_web_sessions where user_id = caller and revoked_at is null;
  if action = 'status' then
    return case when existing.session_id = current_session then 'active' else 'revoked' end;
  end if;
  if action = 'release' then
    update private.admin_web_sessions set revoked_at = now() where session_id = current_session;
    return 'revoked';
  end if;
  if existing.session_id = current_session then return 'active'; end if;
  if action = 'claim' and existing.session_id is not null and existing.device_id <> browser_id
    then return 'conflict'; end if;

  update private.admin_web_sessions set revoked_at = now() where session_id = existing.session_id;
  insert into private.admin_web_sessions (session_id, user_id, device_id)
    values (current_session, caller, browser_id);
  return 'active';
end;
$$;
revoke all on function public.admin_web_session(text, uuid) from public, anon;
grant execute on function public.admin_web_session(text, uuid) to authenticated;

create function private.has_active_admin_web_session()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from private.admin_web_sessions s
    join public.profiles p on p.id = s.user_id
    where s.user_id = (select auth.uid())
      and s.session_id = ((select auth.jwt()) ->> 'session_id')::uuid
      and s.revoked_at is null and p.role = 'admin' and p.is_active
  );
$$;

create or replace function public.uth_admin_profile_read_allowed()
returns boolean language sql stable security definer set search_path = ''
as $$
  select private.has_active_admin_web_session();
$$;

create or replace function public.uth_incident_actor_role()
returns text language sql stable security definer set search_path = ''
as $$
  select role::text from public.profiles
  where id = (select auth.uid()) and is_active
    and (role <> 'admin' or (select public.uth_admin_profile_read_allowed()));
$$;

create or replace function public.admin_user_roles()
returns text[] language plpgsql stable set search_path = ''
as $$
begin
  if not public.uth_admin_profile_read_allowed() then
    raise exception 'Active admin session required' using errcode = '42501';
  end if;
  return array(select value::text from pg_catalog.unnest(pg_catalog.enum_range(null::public.user_role)) as value);
end;
$$;
