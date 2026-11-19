-- Run after fixtures and 20261117090000_approve_and_assign_incident_reports.sql.
-- Every assertion runs in a rollback-only transaction.
begin;
insert into auth.users (id,email,raw_app_meta_data,raw_user_meta_data) values
 ('00000000-0000-0000-0000-000000000001','student@ut.edu.vn','{"app_role":"student"}','{}'),
 ('00000000-0000-0000-0000-000000000002','teacher@ut.edu.vn','{"app_role":"teacher"}','{}'),
 ('00000000-0000-0000-0000-000000000003','admin@ut.edu.vn','{"app_role":"admin"}','{}'),
 ('00000000-0000-0000-0000-000000000004','tech@ut.edu.vn','{"app_role":"technician"}','{}'),
 ('00000000-0000-0000-0000-000000000005','othertech@ut.edu.vn','{"app_role":"technician"}','{}');
insert into public.rooms(id,name,capacity) values ('10000000-0000-0000-0000-000000000001','Phòng kiểm thử',20);
insert into storage.objects(bucket_id,name) values
 ('incident-images','00000000-0000-0000-0000-000000000001/20000000000000000000000000000001.png');
insert into public.incident_reports(id,reporter_id,room_id,title,description,has_photo) values
 ('20000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Tai nghe lỗi','Không nghe được',true),
 ('20000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001','Máy chiếu lỗi','Không lên hình',false);
insert into public.teaching_sections(lecturer_id,code,name) values
 ('00000000-0000-0000-0000-000000000002','LT01','Lập trình');

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  begin
    perform public.approve_incident_report('20000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: student approved a report';
  exception when insufficient_privilege then null; end;
  begin
    perform public.admin_incident_reports();
    raise exception 'FAIL: student read admin inbox';
  exception when insufficient_privilege then null; end;
  begin
    perform public.technician_incident_jobs();
    raise exception 'FAIL: student read technician work';
  exception when insufficient_privilege then null; end;
  assert (select count(*) from public.incident_reports) = 1, 'Student sees only own report';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  assert public.technician_incident_jobs() = '[]'::jsonb, 'Unapproved report leaked into work';
  assert (select count(*) from public.incident_reports) = 0, 'Legacy SELECT leaked unapproved reports';
  begin
    perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');
    raise exception 'FAIL: technician started unapproved work';
  exception when insufficient_privilege then null; end;
  assert (select count(*) from storage.objects) = 0, 'Unapproved evidence leaked';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
do $$ begin
  assert (public.admin_incident_reports()->>'count')::int = 2, 'Admin inbox missing reports';
  assert jsonb_array_length(public.admin_incident_technicians()) = 2, 'Wrong active technician options';
  perform public.approve_incident_report('20000000-0000-0000-0000-000000000001');
  -- Idempotent retry does not create a second assignment or overwrite identity.
  perform public.approve_incident_report('20000000-0000-0000-0000-000000000001');
  assert (public.admin_incident_reports(1,'','approved')->>'count')::int = 1;
  assert (public.admin_incident_reports(1,'Tai nghe','')->>'count')::int = 1;
  assert (select count(*) from storage.objects) = 1, 'Admin cannot read evidence';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
do $$ begin
  assert jsonb_array_length(public.technician_incident_jobs()) = 1, 'Approved queue must be shared';
  assert (select count(*) from storage.objects) = 1, 'Shared work evidence unavailable';
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
select public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  begin
    update public.incident_reports set status = 'cancelled' where id = '20000000-0000-0000-0000-000000000001';
  exception when insufficient_privilege then null; end;
  assert (select status::text from public.incident_reports where id = '20000000-0000-0000-0000-000000000001') <> 'cancelled';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
do $$ begin
  assert public.technician_incident_jobs() = '[]'::jsonb, 'Work leaked to another technician';
  begin
    perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');
    raise exception 'FAIL: another technician accepted work';
  exception when insufficient_privilege then null; end;
  begin
    perform public.incident_evidence_path('20000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: another technician read evidence path';
  exception when insufficient_privilege then null; end;
  assert (select count(*) from storage.objects) = 0, 'Evidence leaked to another technician';
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  assert jsonb_array_length(public.technician_incident_jobs()) = 1;
  assert (select count(*) from storage.objects) = 1, 'Assigned technician cannot read evidence';
  assert public.incident_evidence_path('20000000-0000-0000-0000-000000000001') =
    '00000000-0000-0000-0000-000000000001/20000000000000000000000000000001.png';
  perform public.release_technician_incident('20000000-0000-0000-0000-000000000001');
  assert (select status::text from public.incident_reports) = 'open';
  assert (select assigned_to is null from public.incident_reports);
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
do $$ begin
  assert jsonb_array_length(public.technician_incident_jobs()) = 1, 'Released work must reappear';
  perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  assert public.technician_incident_jobs() = '[]'::jsonb;
  begin
    perform public.release_technician_incident('20000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: another technician released owned work';
  exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000005';
select public.release_technician_incident('20000000-0000-0000-0000-000000000001');
set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');
  perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','open');
  assert (select status::text from public.incident_reports) = 'in_progress';
  begin
    update public.incident_reports set title = 'tampered' where id = '20000000-0000-0000-0000-000000000001';
    raise exception 'FAIL: technician changed report content';
  exception when insufficient_privilege then null; end;
  perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','in_progress');
  perform public.advance_technician_incident('20000000-0000-0000-0000-000000000001','in_progress');
  assert (select status::text from public.incident_reports) = 'resolved';
  assert (select resolved_by from public.incident_reports) = auth.uid();
  assert (select resolved_at is not null and status_updated_at is not null from public.incident_reports);
  begin
    perform public.release_technician_incident('20000000-0000-0000-0000-000000000001');
    raise exception 'FAIL: completed work released';
  exception when insufficient_privilege then null; end;
end $$;

reset role;
update public.profiles set is_active = false where id = '00000000-0000-0000-0000-000000000004';
set local role authenticated;
do $$ begin
  begin perform public.technician_incident_jobs(); raise exception 'FAIL: disabled technician read work';
  exception when insufficient_privilege then null; end;
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
update public.incident_reports set status = 'cancelled' where id = '20000000-0000-0000-0000-000000000002';
do $$ begin
  assert (select status::text from public.incident_reports where id = '20000000-0000-0000-0000-000000000002') = 'cancelled';
  begin
    insert into public.incident_reports(room_id,title,description,course_section,needs_support)
      values ('10000000-0000-0000-0000-000000000001','Lỗi lớp','Không lên hình','Tên lớp tự nhập',true);
    raise exception 'FAIL: unassigned course accepted';
  exception when check_violation then null; end;
  insert into public.incident_reports(room_id,title,description,course_section,needs_support)
    values ('10000000-0000-0000-0000-000000000001','Lỗi lớp','Không lên hình','LT01 · Lập trình',true);
end $$;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-000000000003';
do $$ begin
  begin
    perform public.approve_incident_report('20000000-0000-0000-0000-000000000002');
    raise exception 'FAIL: cancelled report approved';
  exception when check_violation then null; end;
end $$;

reset role;
set local role anon;
do $$ begin
  begin perform public.admin_incident_reports(); raise exception 'FAIL: anonymous read admin inbox';
  exception when insufficient_privilege then null; end;
end $$;
rollback;
