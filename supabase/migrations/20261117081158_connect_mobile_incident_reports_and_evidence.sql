alter table public.incident_reports
  add column report_number bigint generated always as identity unique,
  add column occurred_at timestamptz not null default now(),
  add column course_section text,
  add column needs_support boolean not null default false,
  add column has_photo boolean not null default false,
  add column status_updated_at timestamptz,
  add constraint incident_report_one_asset check (num_nonnulls(room_id, equipment_id) = 1);
create index incident_reports_reporter_created_idx on public.incident_reports (reporter_id, created_at desc);

alter policy "incident_reports: xem" on public.incident_reports
using (reporter_id = (select auth.uid()) or exists (
  select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='technician' and p.is_active
));
alter policy "incident_reports: tạo" on public.incident_reports
with check (reporter_id = (select auth.uid()) and status = 'open' and exists (
  select 1 from public.profiles p where p.id=(select auth.uid()) and p.is_active and p.role in ('student','teacher')
));
create policy incident_report_cancel_own on public.incident_reports for update to authenticated
using (reporter_id = (select auth.uid()) and status='open' and exists (
  select 1 from public.profiles p where p.id=(select auth.uid()) and p.is_active and p.role in ('student','teacher')
))
with check (reporter_id = (select auth.uid()) and status='cancelled');

revoke all on public.incident_reports from public, anon, authenticated;
grant select on public.incident_reports to authenticated;
grant insert (id, room_id, equipment_id, title, description, occurred_at, course_section, needs_support, has_photo),
  update (status, resolved_by, resolved_at) on public.incident_reports to authenticated;

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('incident-images','incident-images',false,5242880,array['image/png']);

create policy incident_images_read_own on storage.objects for select to authenticated
using (bucket_id='incident-images' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy incident_images_insert_own on storage.objects for insert to authenticated
with check (bucket_id='incident-images' and (storage.foldername(name))[1]=(select auth.uid())::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.]png$'
  and not exists (select 1 from public.incident_reports r where r.reporter_id=(select auth.uid())
    and name = r.reporter_id::text || '/' || replace(r.id::text,'-','') || '.png'));
create policy incident_images_update_draft on storage.objects for update to authenticated
using (bucket_id='incident-images' and (storage.foldername(name))[1]=(select auth.uid())::text
  and not exists (select 1 from public.incident_reports r where r.reporter_id=(select auth.uid())
    and name = r.reporter_id::text || '/' || replace(r.id::text,'-','') || '.png'))
with check (bucket_id='incident-images' and (storage.foldername(name))[1]=(select auth.uid())::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.]png$'
  and not exists (select 1 from public.incident_reports r where r.reporter_id=(select auth.uid())
    and name = r.reporter_id::text || '/' || replace(r.id::text,'-','') || '.png'));

create function private.validate_incident_submission()
returns trigger language plpgsql security definer set search_path='' as $$
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
end $$;
revoke all on function private.validate_incident_submission() from public, anon, authenticated;
create trigger validate_incident_submission before insert or update of status, resolved_by, resolved_at
on public.incident_reports for each row execute function private.validate_incident_submission();
