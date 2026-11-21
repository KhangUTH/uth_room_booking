-- OPTIONAL ROLLBACK ONLY: do not run after a successful setup unless reverting.
-- Removes only the policy and helper introduced by 03-admin-profile-read.sql.
-- Existing own-row policy, data and grants are preserved. No CASCADE.
begin;
drop policy if exists "uth_admin_read_all_profiles" on public.profiles;
drop function if exists public.uth_admin_profile_read_allowed();
notify pgrst, 'reload schema';
commit;
