-- READ ONLY. Run in SQL Editor; save the result of each SELECT before changing
-- permissions. No table data, grants, policies or functions are modified.

-- 1. Existing table columns/defaults (including the actual enum type schema).
select table_name, column_name, data_type, udt_schema, udt_name,
       is_nullable, column_default
from information_schema.columns
where table_schema = 'public'
  and table_name in ('profiles', 'rooms', 'equipment')
order by table_name, ordinal_position;

-- 2. Row security state and existing policies. Restrictive policies must also
-- allow a request, even if an additional permissive admin policy is added.
select n.nspname as schema_name, c.relname as table_name,
       c.relrowsecurity as rls_enabled, c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('profiles', 'rooms', 'equipment');

select tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'rooms', 'equipment')
order by tablename, policyname;

-- 3. Existing API role grants, including column-level grants.
select table_name, grantee, privilege_type
from information_schema.table_privileges
where table_schema = 'public'
  and table_name in ('profiles', 'rooms', 'equipment')
  and grantee in ('PUBLIC', 'anon', 'authenticated')
order by table_name, grantee, privilege_type;

select table_name, column_name, grantee, privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name in ('profiles', 'rooms', 'equipment')
  and grantee in ('PUBLIC', 'anon', 'authenticated')
order by table_name, column_name, grantee, privilege_type;

-- 4. Existing helper functions. Check before ever replacing a shared helper.
select n.nspname as schema_name, p.proname as function_name,
       pg_catalog.pg_get_function_identity_arguments(p.oid) as arguments,
       pg_catalog.pg_get_functiondef(p.oid) as definition,
       p.proacl as permissions
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('is_active_admin', 'admin_user_roles');

-- 5. Existing user role values, checks and triggers; no records are read.
select n.nspname as enum_schema, t.typname, e.enumlabel
from pg_catalog.pg_enum e
join pg_catalog.pg_type t on t.oid = e.enumtypid
join pg_catalog.pg_namespace n on n.oid = t.typnamespace
where t.typname = 'user_role'
order by n.nspname, e.enumsortorder;

select c.conrelid::regclass as table_name, c.conname,
       pg_catalog.pg_get_constraintdef(c.oid) as definition
from pg_catalog.pg_constraint c
where c.conrelid in ('public.profiles'::regclass, 'public.rooms'::regclass, 'public.equipment'::regclass)
order by c.conrelid, c.conname;

select t.tgrelid::regclass as table_name, t.tgname,
       pg_catalog.pg_get_triggerdef(t.oid) as definition
from pg_catalog.pg_trigger t
where not t.tgisinternal
  and t.tgrelid in ('auth.users'::regclass, 'public.profiles'::regclass, 'public.rooms'::regclass, 'public.equipment'::regclass)
order by t.tgrelid, t.tgname;
