-- LOCAL INTEGRATION TEST ONLY. Requires a dedicated EMPTY database with this
-- exact name. Never run in Supabase SQL Editor or an application database.
\set ON_ERROR_STOP on
do $$ begin
  if current_database() <> 'uth_crud_isolated_test' or to_regclass('public.profiles') is not null then
    raise exception 'Use a dedicated empty uth_crud_isolated_test database only.';
  end if;
end $$;

create role anon nologin;
create role authenticated nologin;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema auth to authenticated;
grant execute on function auth.uid() to authenticated;

create table public.profiles(id uuid primary key, role text not null, is_active boolean not null);
create table public.rooms(id uuid primary key, name text not null, capacity integer);
create table public.equipment(id uuid primary key, name text not null, room_id uuid references public.rooms(id) on delete set null);
create table public.bookings(id integer primary key, room_id uuid references public.rooms(id) on delete cascade, equipment_id uuid references public.equipment(id) on delete cascade);
create table public.incident_reports(id integer primary key, room_id uuid references public.rooms(id) on delete set null, equipment_id uuid references public.equipment(id) on delete set null);

alter table public.profiles enable row level security;
alter table public.rooms enable row level security;
alter table public.equipment enable row level security;
alter table public.bookings enable row level security;
alter table public.incident_reports enable row level security;
grant select on public.profiles, public.rooms, public.equipment, public.bookings, public.incident_reports to authenticated;
create policy own_profile on public.profiles for select to authenticated using (id = auth.uid());
create policy existing_room_read on public.rooms for select to authenticated using (true);
create policy existing_equipment_read on public.equipment for select to authenticated using (true);
-- Deliberately no child-table read policies: the trigger must see RLS-hidden refs.

insert into public.profiles values
 ('00000000-0000-0000-0000-000000000001', 'admin', true),
 ('00000000-0000-0000-0000-000000000002', 'student', true),
 ('00000000-0000-0000-0000-000000000003', 'admin', false);
insert into public.rooms values
 ('10000000-0000-0000-0000-000000000001', 'booking-room', 40),
 ('10000000-0000-0000-0000-000000000002', 'equipment-room', 40),
 ('10000000-0000-0000-0000-000000000003', 'incident-room', 40);
insert into public.equipment values
 ('20000000-0000-0000-0000-000000000001', 'booking-equipment', null),
 ('20000000-0000-0000-0000-000000000002', 'incident-equipment', null),
 ('20000000-0000-0000-0000-000000000003', 'assigned-equipment', '10000000-0000-0000-0000-000000000002');
insert into public.bookings values (1, '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001');
insert into public.incident_reports values (1, '10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002');

\ir ../sql/03-admin-profile-read.sql
\ir ../sql/04-admin-rooms-crud.sql
\ir ../sql/05-admin-equipment-crud.sql

set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', false);
do $$ declare row_id uuid; begin
  if (select count(*) from public.profiles) <> 3 then raise exception 'Admin profile read failed'; end if;
  if (select count(*) from public.bookings) <> 0 then raise exception 'Fixture must hide bookings via RLS'; end if;
  insert into public.rooms values ('10000000-0000-0000-0000-000000000004', 'empty-room', 20);
  update public.rooms set capacity = 30 where id = '10000000-0000-0000-0000-000000000004';
  if (select capacity from public.rooms where id = '10000000-0000-0000-0000-000000000004') <> 30 then raise exception 'Admin update failed'; end if;
  delete from public.rooms where id = '10000000-0000-0000-0000-000000000004';
  insert into public.equipment values ('20000000-0000-0000-0000-000000000004', 'empty-equipment', null);
  update public.equipment set name = 'updated' where id = '20000000-0000-0000-0000-000000000004';
  if (select name from public.equipment where id = '20000000-0000-0000-0000-000000000004') <> 'updated' then raise exception 'Equipment update failed'; end if;
  delete from public.equipment where id = '20000000-0000-0000-0000-000000000004';

  for row_id in select id from public.rooms loop
    begin
      delete from public.rooms where id = row_id;
      raise exception 'Referenced room was deletable';
    exception when foreign_key_violation then null;
    end;
  end loop;
  for row_id in select id from public.equipment where name in ('booking-equipment', 'incident-equipment') loop
    begin
      delete from public.equipment where id = row_id;
      raise exception 'Referenced equipment was deletable';
    exception when foreign_key_violation then null;
    end;
  end loop;
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', false);
do $$ declare changed integer; begin
  begin
    insert into public.rooms values ('10000000-0000-0000-0000-000000000005', 'unauthorized', 1);
    raise exception 'Student room insert was allowed';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.equipment values ('20000000-0000-0000-0000-000000000005', 'unauthorized', null);
    raise exception 'Student equipment insert was allowed';
  exception when insufficient_privilege then null; end;
  update public.rooms set name = 'unauthorized';
  get diagnostics changed = row_count;
  if changed <> 0 then raise exception 'Student room update was allowed'; end if;
  delete from public.equipment;
  get diagnostics changed = row_count;
  if changed <> 0 then raise exception 'Student equipment delete was allowed'; end if;
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000003', false);
do $$ begin
  begin
    insert into public.rooms values ('10000000-0000-0000-0000-000000000006', 'inactive-admin', 1);
    raise exception 'Inactive admin insert was allowed';
  exception when insufficient_privilege then null; end;
end $$;

reset role;
do $$ begin
  if (select count(*) from public.rooms) <> 3
    or (select count(*) from public.equipment) <> 3
    or (select count(*) from public.bookings) <> 1
    or (select count(*) from public.incident_reports) <> 1 then
    raise exception 'Protected data was changed/deleted';
  end if;
  if not exists (select 1 from public.incident_reports where room_id is not null and equipment_id is not null)
    or not exists (select 1 from public.equipment where room_id is not null) then
    raise exception 'SET NULL changed protected links';
  end if;
end $$;
select 'PASS: active-admin CRUD, unauthorized writes blocked, hidden references protected, CASCADE/SET NULL prevented' as result;
