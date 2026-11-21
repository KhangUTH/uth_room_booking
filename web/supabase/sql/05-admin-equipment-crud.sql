-- Run this step separately in Supabase SQL Editor as postgres.
-- Requires step 03's active-admin helper. Adds a new policy; replaces nothing.
-- Adds equipment CRUD and a BEFORE DELETE guard. No data/foreign key is changed.
begin;

do $check$
declare operation text; policy_command "char";
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Run this step as postgres (BYPASSRLS), so the delete guard can see every reference.';
  end if;
  if pg_catalog.to_regprocedure('public.uth_admin_profile_read_allowed()') is null then
    raise exception 'Run step 03 (admin profile read helper) first.';
  end if;
  if not (select relrowsecurity from pg_catalog.pg_class where oid = 'public.equipment'::regclass) then
    raise exception 'equipment: RLS is disabled. Inspect existing access before enabling it; this step made no changes.';
  end if;
  if exists (select 1 from pg_catalog.pg_policy where polrelid = 'public.equipment'::regclass and not polpermissive) then
    raise exception 'equipment: existing restrictive policies need review before granting CRUD; this step made no changes.';
  end if;
  -- Do not accidentally activate dormant policies for other users by granting
  -- a table privilege they previously lacked. Audit these cases separately.
  foreach operation in array array['INSERT', 'UPDATE', 'DELETE'] loop
    policy_command := case operation when 'INSERT' then 'a' when 'UPDATE' then 'w' else 'd' end;
    if not pg_catalog.has_table_privilege('authenticated', 'public.equipment', operation)
      and exists (
        select 1 from pg_catalog.pg_policy
        where polrelid = 'public.equipment'::regclass
          and polcmd in ('*', policy_command)
          and polpermissive
      ) then
      raise exception 'equipment: existing % policy but no authenticated table grant. Inspect before granting to avoid changing other users access.', operation;
    end if;
  end loop;
  if exists (
    select 1 from pg_catalog.pg_constraint c
    where c.contype = 'f' and c.confrelid = 'public.equipment'::regclass
      and c.confdeltype not in ('a', 'r')
      and not (
        ((c.conrelid = 'public.bookings'::regclass and c.conkey = array[(select attnum from pg_catalog.pg_attribute where attrelid = 'public.bookings'::regclass and attname = 'equipment_id' and not attisdropped)]::smallint[])
        or (c.conrelid = 'public.incident_reports'::regclass and c.conkey = array[(select attnum from pg_catalog.pg_attribute where attrelid = 'public.incident_reports'::regclass and attname = 'equipment_id' and not attisdropped)]::smallint[]))
        and c.confkey = array[(select attnum from pg_catalog.pg_attribute where attrelid = 'public.equipment'::regclass and attname = 'id' and not attisdropped)]::smallint[]
      )
  ) then
    raise exception 'equipment: an additional cascading/rewriting foreign key is not covered by the delete guard. Inspect before enabling DELETE.';
  end if;
end;
$check$;

-- Check every reference as the database owner, even when RLS hides those rows
-- from the caller. Block before CASCADE/SET NULL/SET DEFAULT can run.
-- VOLATILE (the PL/pgSQL default) ensures fresh reads inside this trigger.
create function public.uth_guard_equipment_delete()
returns trigger
language plpgsql volatile security definer
set search_path = ''
as $guard$
begin
  if exists (select 1 from public.bookings where equipment_id = old.id)
    or exists (select 1 from public.incident_reports where equipment_id = old.id) then
    raise exception 'Cannot delete equipment: related records still exist.'
      using errcode = '23503';
  end if;
  return old;
end;
$guard$;

revoke all on function public.uth_guard_equipment_delete() from public, anon, authenticated;

create trigger uth_guard_equipment_delete
before delete on public.equipment
for each row execute function public.uth_guard_equipment_delete();

grant select, insert, update, delete on public.equipment to authenticated;

create policy "uth_admin_equipment_crud"
on public.equipment
as permissive
for all
to authenticated
using ((select public.uth_admin_profile_read_allowed()))
with check ((select public.uth_admin_profile_read_allowed()));

notify pgrst, 'reload schema';
commit;
