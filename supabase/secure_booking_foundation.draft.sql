create schema if not exists private;
alter table public.profiles
  add column if not exists faculty text,
  add column phone text,
  add column notifications_enabled boolean not null default true;

revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

create function private.active_role()
returns public.user_role
language sql stable security definer set search_path = ''
as $$
  select role from public.profiles where id = (select auth.uid()) and is_active
$$;
revoke all on function private.active_role() from public, anon, authenticated;
grant execute on function private.active_role() to authenticated;

do $$
declare p record;
begin
  for p in select tablename, policyname from pg_policies
    where schemaname = 'public' and tablename in ('profiles','rooms','equipment','bookings','incident_reports')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end
$$;

revoke all on public.profiles, public.rooms, public.equipment, public.bookings, public.incident_reports
  from public, anon, authenticated;
grant select on public.profiles, public.rooms, public.equipment, public.bookings, public.incident_reports to authenticated;
grant update (full_name, phone, notifications_enabled) on public.profiles to authenticated;
grant insert (room_id, equipment_id, start_time, end_time, purpose), update (status) on public.bookings to authenticated;
grant insert (room_id, equipment_id, title, description) on public.incident_reports to authenticated;

create policy profiles_read_own on public.profiles for select to authenticated
  using (id = (select auth.uid()));
create policy profiles_edit_own on public.profiles for update to authenticated
  using (id = (select auth.uid()) and is_active)
  with check (id = (select auth.uid()) and is_active);
create policy rooms_read_active on public.rooms for select to authenticated
  using (is_active and (select private.active_role()) in ('student', 'teacher'));
create policy equipment_read_catalog on public.equipment for select to authenticated
  using ((select private.active_role()) in ('student', 'teacher'));
create policy bookings_read_own on public.bookings for select to authenticated
  using (user_id = (select auth.uid()) and (select private.active_role()) in ('student', 'teacher'));
create policy bookings_create_own on public.bookings for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending'
    and (select private.active_role()) in ('student', 'teacher')
    and (room_id is null or (select private.active_role()) = 'teacher'));
create policy bookings_cancel_pending on public.bookings for update to authenticated
  using (user_id = (select auth.uid()) and status = 'pending'
    and (select private.active_role()) in ('student', 'teacher'))
  with check (user_id = (select auth.uid()) and status = 'cancelled'
    and (select private.active_role()) in ('student', 'teacher'));
create policy incidents_read_own on public.incident_reports for select to authenticated
  using (reporter_id = (select auth.uid()) and (select private.active_role()) in ('student', 'teacher'));
create policy incidents_create_own on public.incident_reports for insert to authenticated
  with check (reporter_id = (select auth.uid()) and status = 'open'
    and (select private.active_role()) in ('student', 'teacher'));

revoke execute on function public.handle_new_user(), public.my_role()
  from public, anon, authenticated;

do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    revoke execute on function public.rls_auto_enable() from public, anon, authenticated;
  end if;
end
$$;

alter extension btree_gist set schema extensions;
set local search_path = public, extensions;

alter table public.bookings
  drop constraint no_room_overlap,
  drop constraint no_equipment_overlap,
  add constraint no_room_overlap exclude using gist
    (room_id with =, tstzrange(start_time, end_time, '[)') with &&)
    where (room_id is not null and status = 'approved'),
  add constraint no_equipment_overlap exclude using gist
    (equipment_id with =, tstzrange(start_time, end_time, '[)') with &&)
    where (equipment_id is not null and status = 'approved');

alter table public.bookings
  add column reviewed_by uuid references public.profiles(id),
  add column reviewed_at timestamptz,
  add column status_changed_at timestamptz not null default now();

create function private.enforce_booking_rules()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.status <> 'pending' then
      raise exception 'New bookings must be pending' using errcode = '23514';
    end if;
    new.reviewed_by := null;
    new.reviewed_at := null;
    new.status_changed_at := statement_timestamp();
  elsif new.status is distinct from old.status then
    if not ((old.status = 'pending' and new.status in ('approved', 'rejected', 'cancelled'))
      or (old.status = 'approved' and new.status = 'completed')) then
      raise exception 'Invalid booking status transition' using errcode = '23514';
    end if;
    new.status_changed_at := statement_timestamp();
    if new.status in ('approved', 'rejected') then
      new.reviewed_at := statement_timestamp();
    end if;
  end if;

  if new.status in ('pending', 'approved') then
    if new.room_id is not null then
      perform 1 from public.rooms where id = new.room_id and is_active for share;
      if not found then
        raise exception 'Room is unavailable' using errcode = '23514';
      end if;
    end if;
    if new.equipment_id is not null then
      perform 1 from public.equipment where id = new.equipment_id and status = 'available' for share;
      if not found then
        raise exception 'Equipment is unavailable' using errcode = '23514';
      end if;
    end if;
  end if;

  return new;
end
$$;
revoke all on function private.enforce_booking_rules() from public, anon, authenticated;
create trigger enforce_booking_rules
  before insert or update of status, room_id, equipment_id, start_time, end_time on public.bookings
  for each row execute function private.enforce_booking_rules();

create index equipment_room_idx on public.equipment (room_id);
create index bookings_reviewed_by_idx on public.bookings (reviewed_by);
create index incident_reports_room_idx on public.incident_reports (room_id);
create index incident_reports_equipment_idx on public.incident_reports (equipment_id);
create index incident_reports_resolved_by_idx on public.incident_reports (resolved_by);

create table public.technician_assignments (
  id uuid primary key default gen_random_uuid(),
  technician_id uuid not null references public.profiles(id),
  room_id uuid references public.rooms(id),
  equipment_id uuid references public.equipment(id),
  assigned_at timestamptz not null default now(),
  check (num_nonnulls(room_id, equipment_id) = 1),
  unique nulls not distinct (technician_id, room_id, equipment_id)
);
alter table public.technician_assignments enable row level security;
revoke all on public.technician_assignments from public, anon, authenticated;
grant select on public.technician_assignments to authenticated;
grant select, insert, update, delete on public.technician_assignments to service_role;
create index technician_assignments_room_idx on public.technician_assignments (room_id);
create index technician_assignments_equipment_idx on public.technician_assignments (equipment_id);
create policy assignments_read_own on public.technician_assignments for select to authenticated
  using (technician_id = (select auth.uid()) and (select private.active_role()) = 'technician');
create policy rooms_read_assigned on public.rooms for select to authenticated
  using (exists (select 1 from public.technician_assignments a where a.room_id = rooms.id));
create policy equipment_read_assigned on public.equipment for select to authenticated
  using (exists (select 1 from public.technician_assignments a
    where a.equipment_id = equipment.id or a.room_id = equipment.room_id));
