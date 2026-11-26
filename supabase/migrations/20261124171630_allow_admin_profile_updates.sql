-- The existing phone policy is permissive, so protect the newly granted
-- administrative columns even on the caller's own row.
create function private.guard_profile_admin_fields()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
  if current_user <> 'authenticated' then return new; end if;
  if (new.role, new.is_active) is distinct from (old.role, old.is_active)
    and old.id = (select auth.uid()) then
    raise exception 'Cannot change your own access' using errcode = '42501';
  end if;
  if (new.full_name, new.role, new.is_active, new.student_code, new.lecturer_code, new.employee_code, new.faculty)
    is distinct from
    (old.full_name, old.role, old.is_active, old.student_code, old.lecturer_code, old.employee_code, old.faculty)
    and not public.uth_admin_profile_read_allowed() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.guard_profile_admin_fields() from public, anon, authenticated;

create trigger guard_profile_admin_fields
  before update of full_name, role, is_active, student_code, lecturer_code, employee_code, faculty on public.profiles
  for each row execute function private.guard_profile_admin_fields();

grant update (full_name, role, is_active, student_code, lecturer_code, employee_code, faculty)
  on public.profiles to authenticated;
create policy uth_admin_update_profiles on public.profiles
  for update to authenticated
  using ((select public.uth_admin_profile_read_allowed()))
  with check ((select public.uth_admin_profile_read_allowed()));
