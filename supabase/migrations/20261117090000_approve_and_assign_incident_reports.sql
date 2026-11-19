-- Apply once in Supabase SQL Editor as postgres, after reviewing existing
-- incident triggers. Requires connect_mobile_incident_reports_and_evidence.
-- Also upgrades the earlier assigned-technician draft if it was applied.
-- Compatible with the live 2026-11-17 definitions supplied by the user:
-- private.validate_incident_submission and private.validate_incident_teaching_section.
-- Their content/course validation and state-transition checks remain active.
begin;

alter table public.incident_reports
  add column if not exists approved_at timestamptz,
  add column if not exists approved_by uuid references public.profiles(id),
  add column if not exists assigned_to uuid references public.profiles(id);
alter table public.incident_reports drop constraint if exists incident_approval_complete;
alter table public.incident_reports
  add constraint incident_approval_complete check (
    (approved_at is null and approved_by is null and assigned_to is null)
    or (approved_at is not null and approved_by is not null)
  );
create index if not exists incident_reports_assigned_work_idx
  on public.incident_reports (assigned_to, status, created_at desc)
  where approved_at is not null;
-- Older admin assignments that have not been accepted become shared work.
update public.incident_reports set assigned_to = null where approved_at is not null and status::text = 'open' and assigned_to is not null;

create or replace function public.uth_incident_actor_role()
returns text language sql stable security definer set search_path = ''
as $$
  select role::text from public.profiles where id = auth.uid() and is_active
$$;
revoke all on function public.uth_incident_actor_role() from public, anon;
grant execute on function public.uth_incident_actor_role() to authenticated;

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
        or (old.status='in_progress' and new.status='resolved')
        or (old.status='in_progress' and new.status='open' and old.approved_at is not null
          and old.assigned_to=auth.uid() and new.assigned_to is null
          and public.uth_incident_actor_role()='technician')) then
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

-- This guard also covers writes through any older permissive update policy.
-- Server-side SQL maintenance with no Auth identity remains possible.
create or replace function public.uth_guard_incident_approval()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare actor text := public.uth_incident_actor_role();
begin
  if auth.uid() is null then return new; end if;
  if actor is null then raise exception 'Inactive account' using errcode = '42501'; end if;
  if tg_op = 'INSERT' then
    if new.approved_at is not null or new.approved_by is not null or new.assigned_to is not null then
      raise exception 'New reports must await approval' using errcode = '42501';
    end if;
    return new;
  end if;
  if actor = 'admin' then
    if (to_jsonb(new) - array['approved_at','approved_by','assigned_to','status_updated_at'])
        is distinct from (to_jsonb(old) - array['approved_at','approved_by','assigned_to','status_updated_at'])
      or old.status::text <> 'open' or old.approved_at is not null
      or new.assigned_to is not null then
      raise exception 'Only an open unapproved report can be approved for the shared queue' using errcode = '42501';
    end if;
    new.approved_at := statement_timestamp();
    new.approved_by := auth.uid();
    new.status_updated_at := statement_timestamp();
  elsif actor = 'technician' then
    if old.approved_at is null
      or (to_jsonb(new) - array['status','assigned_to','status_updated_at','resolved_by','resolved_at'])
          is distinct from (to_jsonb(old) - array['status','assigned_to','status_updated_at','resolved_by','resolved_at'])
      or not ((old.status::text = 'open' and old.assigned_to is null and new.status::text = 'in_progress' and new.assigned_to is not distinct from auth.uid())
          or (old.status::text = 'in_progress' and old.assigned_to is not distinct from auth.uid() and
              ((new.status::text = 'resolved' and new.assigned_to is not distinct from auth.uid())
                or (new.status::text = 'open' and new.assigned_to is null)))) then
      raise exception 'Work must be approved and assigned; invalid status transition' using errcode = '42501';
    end if;
    new.status_updated_at := statement_timestamp();
    new.resolved_by := case when new.status::text = 'resolved' then auth.uid() else null end;
    new.resolved_at := case when new.status::text = 'resolved' then statement_timestamp() else null end;
  elsif actor in ('student','teacher') then
    if old.reporter_id is distinct from auth.uid() or old.approved_at is not null
      or old.status::text <> 'open' or new.status::text <> 'cancelled'
      or (to_jsonb(new) - array['status','status_updated_at'])
          is distinct from (to_jsonb(old) - array['status','status_updated_at']) then
      raise exception 'Only your unapproved open report can be cancelled' using errcode = '42501';
    end if;
    new.status_updated_at := statement_timestamp();
  else
    raise exception 'Role not allowed' using errcode = '42501';
  end if;
  return new;
end
$$;
revoke all on function public.uth_guard_incident_approval() from public, anon, authenticated;
drop trigger if exists uth_guard_incident_approval on public.incident_reports;
create trigger uth_guard_incident_approval before insert or update on public.incident_reports
for each row execute function public.uth_guard_incident_approval();

-- No technician can use a legacy SELECT policy to read unapproved reports.
drop policy if exists uth_incidents_approval_visibility on public.incident_reports;
create policy uth_incidents_approval_visibility on public.incident_reports
as restrictive for select to authenticated using (
  case public.uth_incident_actor_role()
    when 'technician' then approved_at is not null and (assigned_to = (select auth.uid()) or (assigned_to is null and status::text = 'open'))
    when 'student' then reporter_id = (select auth.uid())
    when 'teacher' then reporter_id = (select auth.uid())
    when 'admin' then true
    else false
  end
);

-- Internal projection. Never executable by browser/mobile clients directly.
create or replace function public.uth_incident_payload(report_id uuid)
returns jsonb language sql stable security definer set search_path = ''
as $$
  select to_jsonb(i) || jsonb_build_object(
    'asset_name', coalesce(r.name, e.name, 'Tài sản'),
    'reporter_name', coalesce(p.full_name, p.email, 'Người báo cáo'),
    'reporter_role', p.role::text,
    'reporter_code', coalesce(p.student_code, p.lecturer_code, p.employee_code),
    'technician_name', t.full_name
  ) from public.incident_reports i
  left join public.rooms r on r.id = i.room_id
  left join public.equipment e on e.id = i.equipment_id
  left join public.profiles p on p.id = i.reporter_id
  left join public.profiles t on t.id = i.assigned_to
  where i.id = report_id
$$;
revoke all on function public.uth_incident_payload(uuid) from public, anon, authenticated;

create or replace function public.admin_incident_reports(page_number integer default 1, search_text text default '', status_filter text default '')
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
declare result jsonb;
begin
  if public.uth_incident_actor_role() is distinct from 'admin' then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  if page_number < 1 or page_number > 1000000 then raise exception 'Invalid page'; end if;
  with matching as (
    select i.id, i.created_at from public.incident_reports i
    where (search_text = '' or i.title ilike '%' || search_text || '%'
      or i.report_number::text = regexp_replace(search_text, '^#?SC[- ]*', '', 'i'))
    and (status_filter = ''
      or (status_filter = 'pending' and i.status::text = 'open' and i.approved_at is null)
      or (status_filter = 'approved' and i.status::text = 'open' and i.approved_at is not null)
      or (status_filter in ('in_progress','resolved','cancelled') and i.status::text = status_filter))
  ), paged as (
    select * from matching order by created_at desc, id limit 10 offset (page_number - 1) * 10
  ) select jsonb_build_object('count', (select count(*) from matching),
      'rows', coalesce((select jsonb_agg(public.uth_incident_payload(id) order by created_at desc, id) from paged), '[]'::jsonb))
    into result;
  return result;
end
$$;

create or replace function public.admin_incident_technicians()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
begin
  if public.uth_incident_actor_role() is distinct from 'admin' then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  return coalesce((select jsonb_agg(jsonb_build_object('id', id, 'name', coalesce(full_name,email), 'code', employee_code) order by full_name, id)
    from public.profiles where is_active and role::text = 'technician'), '[]'::jsonb);
end
$$;

drop function if exists public.approve_incident_report(uuid,uuid);
create or replace function public.approve_incident_report(report_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare incident public.incident_reports;
begin
  if public.uth_incident_actor_role() is distinct from 'admin' then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  select * into incident from public.incident_reports where id = report_id for update;
  if not found then raise exception 'Report not found' using errcode = 'P0002'; end if;
  if incident.approved_at is not null then
    return public.uth_incident_payload(report_id);
  end if;
  if incident.status::text <> 'open' or incident.approved_at is not null then
    raise exception 'Report is no longer awaiting approval' using errcode = '23514';
  end if;
  update public.incident_reports set approved_at = statement_timestamp(), approved_by = auth.uid()
    where id = report_id;
  return public.uth_incident_payload(report_id);
end
$$;

create or replace function public.technician_incident_jobs()
returns jsonb language plpgsql stable security definer set search_path = ''
as $$
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  return coalesce((select jsonb_agg(public.uth_incident_payload(id) order by needs_support desc, created_at desc, id)
    from public.incident_reports where (assigned_to = auth.uid() or (assigned_to is null and status::text = 'open')) and approved_at is not null
      and status::text in ('open','in_progress','resolved')), '[]'::jsonb);
end
$$;

create or replace function public.advance_technician_incident(report_id uuid, expected_status text)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare incident public.incident_reports; target text;
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  target := case expected_status when 'open' then 'in_progress' when 'in_progress' then 'resolved' else null end;
  if target is null then raise exception 'Invalid transition' using errcode = '23514'; end if;
  select * into incident from public.incident_reports where id = report_id for update;
  if not found or incident.approved_at is null then
    raise exception 'Approved assigned work required' using errcode = '42501';
  end if;
  -- Retrying an acknowledged-late request returns its existing result.
  if incident.status::text = target and incident.assigned_to = auth.uid() then return public.uth_incident_payload(report_id); end if;
  if (expected_status = 'open' and incident.assigned_to is not null)
      or (expected_status = 'in_progress' and incident.assigned_to is distinct from auth.uid()) then
    raise exception 'Work already claimed by another technician' using errcode = '42501';
  end if;
  if incident.status::text <> expected_status then raise exception 'Work status changed; refresh first' using errcode = '23514'; end if;
  update public.incident_reports set status = target::public.incident_status, assigned_to = auth.uid() where id = report_id;
  return public.uth_incident_payload(report_id);
end
$$;

create or replace function public.release_technician_incident(report_id uuid)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare incident public.incident_reports;
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  select * into incident from public.incident_reports where id = report_id for update;
  if not found or incident.approved_at is null or incident.status::text <> 'in_progress'
      or incident.assigned_to is distinct from auth.uid() then
    raise exception 'Only the current owner can return unfinished work' using errcode = '42501';
  end if;
  update public.incident_reports set status = 'open', assigned_to = null where id = report_id;
  return public.uth_incident_payload(report_id);
end
$$;

create or replace function public.incident_evidence_path(report_id uuid)
returns text language plpgsql stable security definer set search_path = ''
as $$
declare incident public.incident_reports; actor text := public.uth_incident_actor_role();
begin
  select * into incident from public.incident_reports where id = report_id;
  if not found or actor is null or not (
    (actor in ('student','teacher') and incident.reporter_id = auth.uid())
    or actor = 'admin'
    or (actor = 'technician' and incident.approved_at is not null and (incident.assigned_to = auth.uid() or (incident.assigned_to is null and incident.status::text = 'open')))
  ) then raise exception 'Evidence access denied' using errcode = '42501'; end if;
  if not incident.has_photo then return null; end if;
  return incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.png';
end
$$;

drop policy if exists uth_incident_images_staff_read on storage.objects;
create policy uth_incident_images_staff_read on storage.objects for select to authenticated using (
  bucket_id = 'incident-images' and exists (
    select 1 from public.incident_reports i
    where storage.objects.name = i.reporter_id::text || '/' || replace(i.id::text, '-', '') || '.png'
      and (public.uth_incident_actor_role() = 'admin'
        or (public.uth_incident_actor_role() = 'technician' and i.approved_at is not null and (i.assigned_to = (select auth.uid()) or (i.assigned_to is null and i.status::text = 'open'))))
  )
);
-- The storage policy needs row visibility for approved assigned work/admin.
-- Existing owner-read policies remain in place.
drop policy if exists uth_incidents_staff_read on public.incident_reports;
create policy uth_incidents_staff_read on public.incident_reports for select to authenticated using (
  public.uth_incident_actor_role() = 'admin'
  or (public.uth_incident_actor_role() = 'technician' and approved_at is not null and (assigned_to = (select auth.uid()) or (assigned_to is null and status::text = 'open')))
);

revoke all on function public.admin_incident_reports(integer,text,text), public.admin_incident_technicians(),
  public.approve_incident_report(uuid), public.technician_incident_jobs(), public.release_technician_incident(uuid),
  public.advance_technician_incident(uuid,text), public.incident_evidence_path(uuid) from public, anon, authenticated;
grant execute on function public.admin_incident_reports(integer,text,text), public.admin_incident_technicians(),
  public.approve_incident_report(uuid), public.technician_incident_jobs(), public.release_technician_incident(uuid),
  public.advance_technician_incident(uuid,text), public.incident_evidence_path(uuid) to authenticated;

notify pgrst, 'reload schema';
commit;
