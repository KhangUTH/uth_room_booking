do $$
begin
  if exists (
    select 1 from public.profiles p
    where p.role = 'admin' and p.is_active
      and not exists (
        select 1 from auth.mfa_factors f
        where f.user_id = p.id and f.status = 'verified' and f.factor_type = 'totp'
      )
  ) then
    raise exception 'Enroll every active administrator in TOTP before enabling UTH Lab admin MFA.';
  end if;
end;
$$;

create or replace function public.uth_admin_profile_read_allowed()
returns boolean language sql stable security definer set search_path = ''
as $$
  select coalesce((select auth.jwt() ->> 'aal') = 'aal2', false)
    and private.has_active_admin_web_session();
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
    raise exception 'Admin MFA required' using errcode = '42501';
  end if;
  return pg_catalog.enum_range(null::public.user_role)::text[];
end;
$$;
