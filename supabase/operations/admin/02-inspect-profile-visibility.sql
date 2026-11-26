-- STEP 2: READ ONLY. Run each SELECT in Supabase SQL Editor as the owner.
-- No profile data, table privileges, policies or functions are changed.
-- Keep the query results so we can distinguish missing profiles from RLS.

-- 1. Actual record counts (SQL Editor owner access, not frontend visibility).
select
  (select count(*) from public.profiles) as total_profiles,
  (select count(*) from auth.users) as total_auth_users,
  (select count(*) from auth.users u
   where not exists (select 1 from public.profiles p where p.id = u.id)
  ) as auth_users_without_profile;

-- 2. Roles present in actual profile data.
select role::text as role, count(*) as profile_count
from public.profiles
group by role
order by role::text;

-- 3. Existing profile policies, including FOR ALL policies that affect reads.
select policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where schemaname = 'public' and tablename = 'profiles'
order by policyname;

-- 4. RLS state and table-level SELECT privilege for the frontend DB role.
-- A false table-level privilege may still be covered by column-level grants.
select c.relrowsecurity as rls_enabled,
       c.relforcerowsecurity as force_rls,
       pg_catalog.has_table_privilege('authenticated', c.oid, 'SELECT') as table_select_granted
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname = 'profiles';
