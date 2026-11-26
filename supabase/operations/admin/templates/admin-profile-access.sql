-- Run in Supabase SQL Editor after public.profiles exists.
-- This only adds profile reads needed by the admin login screen.
-- Review existing write grants/policies separately: users must not be allowed
-- to insert an admin profile or update their own role/is_active.
begin;

alter table public.profiles enable row level security;

grant select (id, email, full_name, role, is_active)
on public.profiles to authenticated;

drop policy if exists "admin_login_read_own_profile" on public.profiles;
create policy "admin_login_read_own_profile"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

commit;
