-- Run with psql on a disposable database after the booking migrations.
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email, raw_app_meta_data) values
  ('00000000-0000-0000-0000-000000000001', 'review-student@ut.edu.vn', '{"app_role":"student"}'),
  ('00000000-0000-0000-0000-000000000002', 'review-teacher@ut.edu.vn', '{"app_role":"teacher"}'),
  ('00000000-0000-0000-0000-000000000003', 'review-admin@ut.edu.vn', '{"app_role":"admin"}');

insert into public.rooms (id, name, capacity) values
  ('10000000-0000-0000-0000-000000000001', 'Review room', 32);
insert into public.equipment (id, name) values
  ('20000000-0000-0000-0000-000000000001', 'Unavailable review device'),
  ('20000000-0000-0000-0000-000000000002', 'Available review device');
insert into public.teaching_sections (id, lecturer_id, code, name) values
  ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'LAB-01', 'Review class');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
insert into public.bookings (room_id, start_time, end_time, student_count) values
  ('10000000-0000-0000-0000-000000000001', '2099-01-01 07:00+07', '2099-01-01 09:00+07', 10);
insert into public.bookings (equipment_id, start_time, end_time) values
  ('20000000-0000-0000-0000-000000000001', '2099-01-01 07:00+07', '2099-01-01 09:00+07'),
  ('20000000-0000-0000-0000-000000000002', '2099-01-01 07:00+07', '2099-01-01 09:00+07');

do $$
begin
  assert (select count(*) from public.uth_admin_bookings) = 0;
  begin
    perform public.uth_admin_decide_booking((select id from public.bookings where student_count = 10), 'approved');
    raise exception 'Student decided a booking';
  exception when insufficient_privilege then null;
  end;
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
insert into public.bookings (room_id, start_time, end_time, teaching_section_id) values
  ('10000000-0000-0000-0000-000000000001', '2099-01-01 09:30+07', '2099-01-01 11:30+07', '30000000-0000-0000-0000-000000000001');

reset role;
update public.bookings set start_time = '2000-01-01 07:00+07', end_time = '2000-01-01 09:00+07' where student_count = 10;
update public.equipment set status = 'broken' where id = '20000000-0000-0000-0000-000000000001';

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000003', true);
do $$
declare
  room_request uuid := (select id from public.uth_admin_bookings where teaching_section_code = 'LAB-01' and teaching_section_name = 'Review class');
  available_request uuid := (select id from public.uth_admin_bookings where equipment_name = 'Available review device');
  unavailable_request uuid := (select id from public.uth_admin_bookings where equipment_name = 'Unavailable review device');
  expired_request uuid := (select id from public.uth_admin_bookings where student_count = 10);
begin
  assert room_request is not null and available_request is not null and unavailable_request is not null and expired_request is not null;
  assert (select count(*) from public.uth_admin_bookings where status = 'pending') = 4;
  perform public.uth_admin_decide_booking(room_request, 'approved');
  perform public.uth_admin_decide_booking(available_request, 'approved');
  begin
    perform public.uth_admin_decide_booking(room_request, 'rejected');
    raise exception 'A decision was overwritten';
  exception when no_data_found then null;
  end;
  begin
    perform public.uth_admin_decide_booking(expired_request, 'approved');
    raise exception 'Expired booking was approved';
  exception when check_violation then
    assert sqlerrm = 'booking_already_started';
  end;
  begin
    perform public.uth_admin_decide_booking(unavailable_request, 'approved');
    raise exception 'Unavailable device booking was approved';
  exception when check_violation then
    assert sqlerrm = 'booking_asset_unavailable';
  end;
  perform public.uth_admin_decide_booking(unavailable_request, 'rejected');
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
do $$
begin
  assert (select count(*) from public.bookings where status = 'approved') = 1;
  assert exists (select 1 from public.app_notifications where title = 'Đăng ký đã được duyệt');
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
do $$
begin
  assert (select count(*) from public.bookings where equipment_id is not null and status = 'rejected') = 1;
  assert (select count(*) from public.bookings where equipment_id is not null and status = 'approved') = 1;
  assert exists (select 1 from public.app_notifications where title = 'Đăng ký bị từ chối');
  assert exists (select 1 from public.mobile_busy_booking_slots('2099-01-01') where room_id is not null);
  assert exists (select 1 from public.mobile_busy_booking_slots('2099-01-01') where equipment_id = '20000000-0000-0000-0000-000000000002');
  assert not exists (select 1 from public.mobile_busy_booking_slots('2099-01-01') where equipment_id = '20000000-0000-0000-0000-000000000001');
end $$;

rollback;
