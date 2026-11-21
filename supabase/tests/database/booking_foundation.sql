-- Run with psql against a disposable database after the draft migration.
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email, raw_app_meta_data) values
  ('00000000-0000-0000-0000-000000000001', 'test-student@ut.edu.vn', '{"app_role":"student"}'),
  ('00000000-0000-0000-0000-000000000002', 'test-teacher@ut.edu.vn', '{"app_role":"teacher"}'),
  ('00000000-0000-0000-0000-000000000003', 'test-technician@ut.edu.vn', '{"app_role":"technician"}'),
  ('00000000-0000-0000-0000-000000000004', 'test-inactive@ut.edu.vn', '{"app_role":"student"}');
update public.profiles set is_active = false where id = '00000000-0000-0000-0000-000000000004';

insert into public.rooms (id, name, is_active) values
  ('10000000-0000-0000-0000-000000000001', 'Test room', true),
  ('10000000-0000-0000-0000-000000000002', 'Closed room', false);
insert into public.equipment (id, name, room_id, status) values
  ('20000000-0000-0000-0000-000000000001', 'Assigned device', '10000000-0000-0000-0000-000000000001', 'available'),
  ('20000000-0000-0000-0000-000000000002', 'Broken device', null, 'broken');
insert into public.technician_assignments (technician_id, room_id)
values ('00000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
insert into public.bookings (equipment_id, start_time, end_time, purpose) values
  ('20000000-0000-0000-0000-000000000001', '2099-01-01 01:00Z', '2099-01-01 02:00Z', 'approve'),
  ('20000000-0000-0000-0000-000000000001', '2099-01-01 01:30Z', '2099-01-01 02:30Z', 'overlap'),
  ('20000000-0000-0000-0000-000000000001', '2099-01-01 02:00Z', '2099-01-01 03:00Z', 'adjacent'),
  ('20000000-0000-0000-0000-000000000001', '2099-01-01 02:00Z', '2099-01-01 03:00Z', 'cancel');
update public.profiles
  set full_name = 'Student test', phone = '0900000000', notifications_enabled = false;
update public.bookings set status = 'cancelled' where purpose = 'cancel';

do $$
begin
  assert (select count(*) from public.profiles) = 1;
  assert (select phone = '0900000000' and not notifications_enabled from public.profiles);
  assert (select status from public.bookings where purpose = 'cancel') = 'cancelled';
  begin
    update public.profiles set role = 'technician';
    raise exception 'Student could modify role';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set faculty = 'Other faculty', email = 'other@ut.edu.vn';
    raise exception 'Student could modify managed profile fields';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.bookings (room_id, start_time, end_time)
    values ('10000000-0000-0000-0000-000000000001', '2099-01-01 01:00Z', '2099-01-01 02:00Z');
    raise exception 'Student could book whole room';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.bookings (equipment_id, start_time, end_time)
    values ('20000000-0000-0000-0000-000000000002', '2099-01-01 01:00Z', '2099-01-01 02:00Z');
    raise exception 'Broken device could be booked';
  exception when check_violation then null;
  end;
end
$$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
do $$
begin
  assert (select count(*) from public.bookings) = 0;
  begin
    insert into public.bookings (room_id, start_time, end_time)
    values ('10000000-0000-0000-0000-000000000002', '2099-01-01 01:00Z', '2099-01-01 02:00Z');
    raise exception 'Closed room could be booked';
  exception when check_violation then null;
  end;
end
$$;
insert into public.bookings (room_id, start_time, end_time, purpose) values
  ('10000000-0000-0000-0000-000000000001', '2099-01-01 01:00Z', '2099-01-01 02:00Z', 'room-first'),
  ('10000000-0000-0000-0000-000000000001', '2099-01-01 01:30Z', '2099-01-01 02:30Z', 'room-overlap');

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000003', true);
do $$
begin
  assert (select count(*) from public.rooms) = 1;
  assert (select count(*) from public.equipment) = 1;
  assert (select count(*) from public.bookings) = 0;
end
$$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000004', true);
do $$
begin
  assert (select count(*) from public.equipment) = 0;
  update public.profiles set phone = '0900000001';
  assert not found;
end
$$;

reset role;
update public.bookings set status = 'approved' where purpose in ('approve', 'adjacent', 'room-first');
do $$
begin
  assert (select count(*) from public.bookings where status = 'approved') = 3;
  begin
    update public.bookings set status = 'approved' where purpose = 'overlap';
    raise exception 'Equipment approvals overlap';
  exception when exclusion_violation then null;
  end;
  begin
    update public.bookings set status = 'approved' where purpose = 'room-overlap';
    raise exception 'Room approvals overlap';
  exception when exclusion_violation then null;
  end;
end
$$;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
do $$
begin
  update public.bookings set status = 'cancelled' where purpose = 'approve';
  assert not found;
  assert (select status from public.bookings where purpose = 'approve') = 'approved';
end
$$;

rollback;
