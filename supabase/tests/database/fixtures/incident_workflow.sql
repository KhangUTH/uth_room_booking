-- Disposable local PostgreSQL only, after standalone_auth.sql/current_schema.sql.
-- Models the already deployed mobile-report fields and Supabase Storage RLS.
alter type public.user_role add value 'admin';
alter type public.incident_status add value 'cancelled';
alter table public.profiles add column lecturer_code text, add column employee_code text;
alter table public.incident_reports
  add column report_number bigint generated always as identity unique,
  add column occurred_at timestamptz not null default now(),
  add column course_section text,
  add column needs_support boolean not null default false,
  add column has_photo boolean not null default false,
  add column status_updated_at timestamptz;
create schema storage;
create table storage.objects (id uuid default gen_random_uuid() primary key, bucket_id text, name text);
alter table storage.objects enable row level security;
grant usage on schema storage to authenticated;
grant select on storage.objects to authenticated;
create policy incidents_owner_cancel_fixture on public.incident_reports for update to authenticated
  using (reporter_id = auth.uid() and status = 'open')
  with check (reporter_id = auth.uid() and status = 'cancelled');

-- Live trigger/policy snapshot supplied by the user on 2026-11-17.
alter table public.rooms add column is_archived boolean not null default false;
create schema private;
create table public.teaching_sections (id uuid primary key default gen_random_uuid(), lecturer_id uuid references public.profiles(id), code text not null, name text not null);
create function storage.foldername(name text) returns text[] language sql immutable as $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'),1)-1] $$;
CREATE OR REPLACE FUNCTION private.validate_incident_submission()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare role_of_reporter public.user_role;
begin
  if tg_op = 'UPDATE' then
    if old.status is distinct from new.status then
      if not ((old.status='open' and new.status in ('in_progress','cancelled'))
        or (old.status='in_progress' and new.status='resolved')) then
        raise exception 'invalid_incident_status_transition' using errcode='23514';
      end if;
      new.status_updated_at := statement_timestamp();
    end if;
    if new.status='cancelled' and (
      new.resolved_by is distinct from old.resolved_by or new.resolved_at is distinct from old.resolved_at
    ) then raise exception 'resolution_fields_not_allowed' using errcode='23514'; end if;
    return new;
  end if;

  select p.role into role_of_reporter from public.profiles p where p.id=new.reporter_id and p.is_active;
  if role_of_reporter is null or role_of_reporter not in ('student','teacher')
    or (role_of_reporter='student' and (new.needs_support or new.course_section is not null))
    or (new.needs_support and coalesce(length(trim(new.course_section)),0)=0)
  then raise exception 'invalid_incident_reporter_details' using errcode='23514'; end if;

  if length(trim(new.title)) not between 1 and 250
    or coalesce(length(trim(new.description)),0) not between 1 and 6000
    or length(new.course_section) > 250
  then raise exception 'invalid_incident_content' using errcode='23514'; end if;

  if new.room_id is not null and not exists(select 1 from public.rooms r where r.id=new.room_id and not r.is_archived)
    or new.equipment_id is not null and not exists(select 1 from public.equipment e where e.id=new.equipment_id and e.room_id is null)
  then raise exception 'unknown_incident_asset' using errcode='23514'; end if;

  if new.has_photo and not exists (
    select 1 from storage.objects o where o.bucket_id='incident-images'
    and o.name=new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.png'
  ) then raise exception 'incident_evidence_missing' using errcode='23514'; end if;
  return new;
end $function$
;
CREATE TRIGGER validate_incident_submission BEFORE INSERT OR UPDATE OF status, resolved_by, resolved_at ON public.incident_reports FOR EACH ROW EXECUTE FUNCTION private.validate_incident_submission();
CREATE OR REPLACE FUNCTION private.validate_incident_teaching_section()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if new.course_section is not null and not exists (
    select 1 from public.teaching_sections s
    where s.lecturer_id = new.reporter_id
      and new.course_section = s.code || ' · ' || s.name
  ) then
    raise exception 'incident_teaching_section_not_assigned' using errcode='23514';
  end if;
  return new;
end $function$
;
CREATE TRIGGER validate_incident_teaching_section BEFORE INSERT ON public.incident_reports FOR EACH ROW EXECUTE FUNCTION private.validate_incident_teaching_section();
drop policy incidents_owner_cancel_fixture on public.incident_reports;
drop policy if exists "incident_report_cancel_own" on public.incident_reports;
create policy "incident_report_cancel_own" on public.incident_reports for UPDATE to authenticated using (((reporter_id = ( SELECT auth.uid() AS uid)) AND (status = 'open'::incident_status) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND p.is_active AND (p.role = ANY (ARRAY['student'::user_role, 'teacher'::user_role]))))))) with check (((reporter_id = ( SELECT auth.uid() AS uid)) AND (status = 'cancelled'::incident_status)));
drop policy if exists "incident_reports: technician xử lý" on public.incident_reports;
create policy "incident_reports: technician xử lý" on public.incident_reports for UPDATE to authenticated using ((my_role() = 'technician'::user_role)) with check ((my_role() = 'technician'::user_role));
drop policy if exists "incident_reports: tạo" on public.incident_reports;
create policy "incident_reports: tạo" on public.incident_reports for INSERT to authenticated with check (((reporter_id = ( SELECT auth.uid() AS uid)) AND (status = 'open'::incident_status) AND (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND p.is_active AND (p.role = ANY (ARRAY['student'::user_role, 'teacher'::user_role])))))));
drop policy if exists "incident_reports: xem" on public.incident_reports;
create policy "incident_reports: xem" on public.incident_reports for SELECT to authenticated using (((reporter_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = ( SELECT auth.uid() AS uid)) AND (p.role = 'technician'::user_role) AND p.is_active)))));
drop policy if exists "incident_images_insert_own" on storage.objects;
create policy "incident_images_insert_own" on storage.objects for INSERT to authenticated with check (((bucket_id = 'incident-images'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND (name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.]png$'::text) AND (NOT (EXISTS ( SELECT 1
   FROM incident_reports r
  WHERE ((r.reporter_id = ( SELECT auth.uid() AS uid)) AND (objects.name = ((((r.reporter_id)::text || '/'::text) || replace((r.id)::text, '-'::text, ''::text)) || '.png'::text))))))));
drop policy if exists "incident_images_read_own" on storage.objects;
create policy "incident_images_read_own" on storage.objects for SELECT to authenticated using (((bucket_id = 'incident-images'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text)));
drop policy if exists "incident_images_update_draft" on storage.objects;
create policy "incident_images_update_draft" on storage.objects for UPDATE to authenticated using (((bucket_id = 'incident-images'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND (NOT (EXISTS ( SELECT 1
   FROM incident_reports r
  WHERE ((r.reporter_id = ( SELECT auth.uid() AS uid)) AND (objects.name = ((((r.reporter_id)::text || '/'::text) || replace((r.id)::text, '-'::text, ''::text)) || '.png'::text)))))))) with check (((bucket_id = 'incident-images'::text) AND ((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) AND (name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.]png$'::text) AND (NOT (EXISTS ( SELECT 1
   FROM incident_reports r
  WHERE ((r.reporter_id = ( SELECT auth.uid() AS uid)) AND (objects.name = ((((r.reporter_id)::text || '/'::text) || replace((r.id)::text, '-'::text, ''::text)) || '.png'::text))))))));
drop policy if exists "profile_avatar_insert" on storage.objects;
create policy "profile_avatar_insert" on storage.objects for INSERT to authenticated with check (((bucket_id = 'profile-avatars'::text) AND (name = ((( SELECT auth.uid() AS uid))::text || '/avatar.png'::text))));
drop policy if exists "profile_avatar_select" on storage.objects;
create policy "profile_avatar_select" on storage.objects for SELECT to authenticated using (((bucket_id = 'profile-avatars'::text) AND (name = ((( SELECT auth.uid() AS uid))::text || '/avatar.png'::text))));
drop policy if exists "profile_avatar_update" on storage.objects;
create policy "profile_avatar_update" on storage.objects for UPDATE to authenticated using (((bucket_id = 'profile-avatars'::text) AND (name = ((( SELECT auth.uid() AS uid))::text || '/avatar.png'::text)))) with check (((bucket_id = 'profile-avatars'::text) AND (name = ((( SELECT auth.uid() AS uid))::text || '/avatar.png'::text))));
revoke all on public.incident_reports from public, anon, authenticated;
grant select on public.incident_reports to authenticated;
grant insert (id,room_id,equipment_id,title,description,course_section,needs_support,occurred_at,has_photo), update (status,resolved_by,resolved_at) on public.incident_reports to authenticated;
grant insert,update on storage.objects to authenticated;
