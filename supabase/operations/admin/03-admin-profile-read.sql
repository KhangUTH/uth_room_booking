-- STEP 3: Allow active admins to SELECT all profiles.
-- Based on the inspected state: RLS enabled, FORCE RLS false,
-- authenticated already has SELECT, and the current policy permits own-row reads.
-- Run once in Supabase SQL Editor as postgres/a BYPASSRLS database owner.
-- No existing policy/function is replaced. No table/data/write grant is changed.
begin;

do $check$
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Run this step in SQL Editor as postgres (BYPASSRLS).';
  end if;
end;
$check$;

-- SECURITY DEFINER avoids recursively invoking the profiles SELECT policy.
-- It only answers whether the caller's own profile is an active admin.
create function public.uth_admin_profile_read_allowed()
returns boolean
language sql stable security definer
set search_path = ''
as $body$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role::text = 'admin'
      and is_active = true
  );
$body$;

revoke all on function public.uth_admin_profile_read_allowed() from public, anon;
grant execute on function public.uth_admin_profile_read_allowed() to authenticated;

create policy "uth_admin_read_all_profiles"
on public.profiles
as permissive
for select
to authenticated
using ((select public.uth_admin_profile_read_allowed()));

notify pgrst, 'reload schema';
commit;
