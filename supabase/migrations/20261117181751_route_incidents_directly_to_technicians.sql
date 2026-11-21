alter table public.incident_reports
  drop constraint incident_approval_complete,
  add constraint incident_approval_complete check (
    (approved_at is null) = (approved_by is null)
  );

CREATE OR REPLACE FUNCTION public.advance_technician_incident(report_id uuid, expected_status text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare incident public.incident_reports; target text;
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  target := case expected_status when 'open' then 'in_progress' when 'in_progress' then 'resolved' else null end;
  if target is null then raise exception 'Invalid transition' using errcode = '23514'; end if;
  select * into incident from public.incident_reports where id = report_id for update;
  if not found then
    raise exception 'Incident report not found' using errcode = '42501';
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
$function$;

CREATE OR REPLACE FUNCTION public.incident_evidence_path(report_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare incident public.incident_reports; actor text := public.uth_incident_actor_role();
begin
  select * into incident from public.incident_reports where id = report_id;
  if not found or actor is null or not (
    (actor in ('student','teacher') and incident.reporter_id = auth.uid())
    or actor = 'admin'
    or (actor = 'technician' and (incident.assigned_to = auth.uid() or (incident.assigned_to is null and incident.status::text = 'open')))
  ) then raise exception 'Evidence access denied' using errcode = '42501'; end if;
  if not incident.has_photo then return null; end if;
  return (
      select o.name from storage.objects o
      where o.bucket_id = 'incident-images'
        and o.name in (
          incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.jpg',
          incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.png'
        )
      order by (right(o.name, 4) = '.jpg') desc
      limit 1
    );
end
$function$;

CREATE OR REPLACE FUNCTION public.release_technician_incident(report_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare incident public.incident_reports;
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  select * into incident from public.incident_reports where id = report_id for update;
  if not found or incident.status::text <> 'in_progress'
      or incident.assigned_to is distinct from auth.uid() then
    raise exception 'Only the current owner can return unfinished work' using errcode = '42501';
  end if;
  update public.incident_reports set status = 'open', assigned_to = null where id = report_id;
  return public.uth_incident_payload(report_id);
end
$function$;

CREATE OR REPLACE FUNCTION public.technician_incident_jobs()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if public.uth_incident_actor_role() is distinct from 'technician' then
    raise exception 'Active technician required' using errcode = '42501';
  end if;
  return coalesce((select jsonb_agg(public.uth_incident_payload(id) order by needs_support desc, created_at desc, id)
    from public.incident_reports where (assigned_to = auth.uid() or (assigned_to is null and status::text = 'open'))
      and status::text in ('open','in_progress','resolved')), '[]'::jsonb);
end
$function$;

CREATE OR REPLACE FUNCTION public.uth_guard_incident_approval()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare actor text := public.uth_incident_actor_role();
begin
  if auth.uid() is null then return new; end if;
  if actor is null then raise exception 'Inactive account' using errcode = '42501'; end if;
  if tg_op = 'INSERT' then
    if new.approved_at is not null or new.approved_by is not null or new.assigned_to is not null then
      raise exception 'New reports must be unassigned' using errcode = '42501';
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
    if (to_jsonb(new) - array['status','assigned_to','status_updated_at','resolved_by','resolved_at'])
          is distinct from (to_jsonb(old) - array['status','assigned_to','status_updated_at','resolved_by','resolved_at'])
      or not ((old.status::text = 'open' and old.assigned_to is null and new.status::text = 'in_progress' and new.assigned_to is not distinct from auth.uid())
          or (old.status::text = 'in_progress' and old.assigned_to is not distinct from auth.uid() and
              ((new.status::text = 'resolved' and new.assigned_to is not distinct from auth.uid())
                or (new.status::text = 'open' and new.assigned_to is null)))) then
      raise exception 'Invalid technician status transition' using errcode = '42501';
    end if;
    new.status_updated_at := statement_timestamp();
    new.resolved_by := case when new.status::text = 'resolved' then auth.uid() else null end;
    new.resolved_at := case when new.status::text = 'resolved' then statement_timestamp() else null end;
  elsif actor in ('student','teacher') then
    if old.reporter_id is distinct from auth.uid() or old.assigned_to is not null
      or old.status::text <> 'open' or new.status::text <> 'cancelled'
      or (to_jsonb(new) - array['status','status_updated_at'])
          is distinct from (to_jsonb(old) - array['status','status_updated_at']) then
      raise exception 'Only your unassigned open report can be cancelled' using errcode = '42501';
    end if;
    new.status_updated_at := statement_timestamp();
  else
    raise exception 'Role not allowed' using errcode = '42501';
  end if;
  return new;
end
$function$;

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
        or (old.status='in_progress' and new.status='open'
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
    and o.name in (
      new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.jpg',
      new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.png'
    )
  ) then raise exception 'incident_evidence_missing' using errcode='23514'; end if;
  return new;
end $function$;

alter policy uth_incident_images_staff_read on storage.objects using (((bucket_id = 'incident-images'::text) AND (EXISTS ( SELECT 1
   FROM incident_reports i
  WHERE (((objects.name = ((((i.reporter_id)::text || '/'::text) || replace((i.id)::text, '-'::text, ''::text)) || '.jpg'::text)) OR (objects.name = ((((i.reporter_id)::text || '/'::text) || replace((i.id)::text, '-'::text, ''::text)) || '.png'::text))) AND ((uth_incident_actor_role() = 'admin'::text) OR ((uth_incident_actor_role() = 'technician'::text) AND ((i.assigned_to = ( SELECT auth.uid() AS uid)) OR ((i.assigned_to IS NULL) AND ((i.status)::text = 'open'::text))))))))));

alter policy uth_incidents_approval_visibility on public.incident_reports using (
CASE uth_incident_actor_role()
    WHEN 'technician'::text THEN (((assigned_to = ( SELECT auth.uid() AS uid)) OR ((assigned_to IS NULL) AND ((status)::text = 'open'::text))))
    WHEN 'student'::text THEN (reporter_id = ( SELECT auth.uid() AS uid))
    WHEN 'teacher'::text THEN (reporter_id = ( SELECT auth.uid() AS uid))
    WHEN 'admin'::text THEN true
    ELSE false
END);

alter policy uth_incidents_staff_read on public.incident_reports using (((uth_incident_actor_role() = 'admin'::text) OR ((uth_incident_actor_role() = 'technician'::text) AND ((assigned_to = ( SELECT auth.uid() AS uid)) OR ((assigned_to IS NULL) AND ((status)::text = 'open'::text))))));

drop trigger notify_incident_claimed on public.incident_reports;
create trigger notify_incident_claimed
after update of status on public.incident_reports
for each row
when (
  old.status = 'open'
  and new.status = 'in_progress'
  and new.assigned_to is not null
)
execute function private.notify_incident_claimed();
