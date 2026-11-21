-- Restore application-owned functions and policies recorded outside migration history.

CREATE OR REPLACE FUNCTION public.admin_user_roles()
 RETURNS text[]
 LANGUAGE plpgsql
 STABLE
 SET search_path TO ''
AS $function$
      begin
        if not exists (
          select 1 from public.profiles
          where id = (select auth.uid())
            and role::text = 'admin'
            and is_active = true
        ) then
          raise exception 'Admin access required' using errcode = '42501';
        end if;

        return array(
          select enum_value::text
          from pg_catalog.unnest(pg_catalog.enum_range(null::public.user_role)) as role_values(enum_value)
        );
      end;
      $function$;
revoke all on function public.admin_user_roles() from public, anon, authenticated;
grant execute on function public.admin_user_roles() to authenticated, service_role;

CREATE OR REPLACE FUNCTION public.email_by_student_code(code text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select email
  from public.profiles
  where student_code = code and is_active
  limit 1
$function$;
revoke all on function public.email_by_student_code(text) from public, anon, authenticated;
grant execute on function public.email_by_student_code(text) to service_role;

CREATE OR REPLACE FUNCTION public.uth_admin_profile_read_allowed()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid())
      and role::text = 'admin'
      and is_active = true
  );
$function$;
revoke all on function public.uth_admin_profile_read_allowed() from public, anon, authenticated;
grant execute on function public.uth_admin_profile_read_allowed() to authenticated, service_role;

CREATE OR REPLACE FUNCTION public.uth_guard_equipment_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if exists (select 1 from public.bookings where equipment_id = old.id)
    or exists (select 1 from public.incident_reports where equipment_id = old.id) then
    raise exception 'Cannot delete equipment: related records still exist.'
      using errcode = '23503';
  end if;
  return old;
end;
$function$;
revoke all on function public.uth_guard_equipment_delete() from public, anon, authenticated;
grant execute on function public.uth_guard_equipment_delete() to service_role;

CREATE OR REPLACE FUNCTION public.uth_guard_rooms_delete()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if exists (select 1 from public.bookings where room_id = old.id)
    or exists (select 1 from public.equipment where room_id = old.id)
    or exists (select 1 from public.incident_reports where room_id = old.id) then
    raise exception 'Cannot delete rooms: related records still exist.'
      using errcode = '23503';
  end if;
  return old;
end;
$function$;
revoke all on function public.uth_guard_rooms_delete() from public, anon, authenticated;
grant execute on function public.uth_guard_rooms_delete() to service_role;

CREATE TRIGGER uth_guard_equipment_delete BEFORE DELETE ON public.equipment FOR EACH ROW EXECUTE FUNCTION public.uth_guard_equipment_delete();
CREATE TRIGGER uth_guard_rooms_delete BEFORE DELETE ON public.rooms FOR EACH ROW EXECUTE FUNCTION public.uth_guard_rooms_delete();

create policy uth_admin_read_all_profiles on public.profiles for select to authenticated
using ((select public.uth_admin_profile_read_allowed()));

create policy uth_admin_rooms_crud on public.rooms for all to authenticated
using ((select public.uth_admin_profile_read_allowed()))
with check ((select public.uth_admin_profile_read_allowed()));

create policy uth_admin_equipment_crud on public.equipment for all to authenticated
using ((select public.uth_admin_profile_read_allowed()))
with check ((select public.uth_admin_profile_read_allowed()));
