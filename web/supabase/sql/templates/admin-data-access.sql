-- OPTIONAL FULL POLICY TEMPLATE: do not run as the first setup step.
-- Start with 00-inspect-admin-access.sql and 01-admin-user-roles.sql.
-- This template restricts existing write flows; review current policies first.
-- Existing schema: public.profiles, public.rooms, public.equipment,
-- and public.user_role. Run in SQL Editor as the database owner.
-- Authenticated admins manage data. Browser clients cannot insert/delete
-- profiles or delete rooms/equipment; creation of Auth users is server-only.
begin;

create or replace function public.is_active_admin()
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role::text = 'admin' and is_active = true
  );
$$;

revoke all on function public.is_active_admin() from public;
grant execute on function public.is_active_admin() to anon, authenticated;

create or replace function public.admin_user_roles()
returns text[]
language plpgsql stable security definer
set search_path = ''
as $$
begin
  if not public.is_active_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return array(select value::text from unnest(enum_range(null::public.user_role)) as value);
end;
$$;

revoke all on function public.admin_user_roles() from public;
grant execute on function public.admin_user_roles() to authenticated;

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.equipment enable row level security;

grant select on public.profiles, public.rooms, public.equipment to authenticated;
grant update (full_name, student_code, lecturer_code, employee_code, faculty, role, is_active)
  on public.profiles to authenticated;
grant insert, update on public.rooms, public.equipment to authenticated;
revoke insert, update, delete on public.profiles, public.rooms, public.equipment from anon;
revoke insert, delete on public.profiles from authenticated;
revoke delete on public.rooms, public.equipment from authenticated;

drop policy if exists "admin_login_read_own_profile" on public.profiles;
create policy "admin_login_read_own_profile" on public.profiles
  for select to authenticated using (id = (select auth.uid()));

drop policy if exists "admin_manage_read_profiles" on public.profiles;
create policy "admin_manage_read_profiles" on public.profiles
  for select to authenticated using ((select public.is_active_admin()));

drop policy if exists "admin_manage_update_profiles" on public.profiles;
create policy "admin_manage_update_profiles" on public.profiles
  for update to authenticated
  using ((select public.is_active_admin())) with check ((select public.is_active_admin()));

-- Restrictive policies also constrain pre-existing permissive write policies.
drop policy if exists "admin_profiles_update_guard" on public.profiles;
create policy "admin_profiles_update_guard" on public.profiles as restrictive
  for update to anon, authenticated
  using ((select public.is_active_admin())) with check ((select public.is_active_admin()));

drop policy if exists "admin_profiles_insert_guard" on public.profiles;
create policy "admin_profiles_insert_guard" on public.profiles as restrictive
  for insert to anon, authenticated with check (false);

drop policy if exists "admin_profiles_delete_guard" on public.profiles;
create policy "admin_profiles_delete_guard" on public.profiles as restrictive
  for delete to anon, authenticated using (false);

do $$
declare entity text;
begin
  foreach entity in array array['rooms', 'equipment'] loop
    execute format('drop policy if exists admin_manage_read on public.%I', entity);
    execute format('create policy admin_manage_read on public.%I for select to authenticated using ((select public.is_active_admin()))', entity);
    execute format('drop policy if exists admin_manage_insert on public.%I', entity);
    execute format('create policy admin_manage_insert on public.%I for insert to authenticated with check ((select public.is_active_admin()))', entity);
    execute format('drop policy if exists admin_manage_update on public.%I', entity);
    execute format('create policy admin_manage_update on public.%I for update to authenticated using ((select public.is_active_admin())) with check ((select public.is_active_admin()))', entity);
    execute format('drop policy if exists admin_insert_guard on public.%I', entity);
    execute format('create policy admin_insert_guard on public.%I as restrictive for insert to anon, authenticated with check ((select public.is_active_admin()))', entity);
    execute format('drop policy if exists admin_update_guard on public.%I', entity);
    execute format('create policy admin_update_guard on public.%I as restrictive for update to anon, authenticated using ((select public.is_active_admin())) with check ((select public.is_active_admin()))', entity);
    execute format('drop policy if exists admin_delete_guard on public.%I', entity);
    execute format('create policy admin_delete_guard on public.%I as restrictive for delete to anon, authenticated using (false)', entity);
  end loop;
end;
$$;

commit;
