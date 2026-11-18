update storage.buckets
set allowed_mime_types = array['image/png', 'image/jpeg']
where id = 'incident-images';

alter policy incident_images_insert_own on storage.objects with check (
  bucket_id = 'incident-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.](png|jpg)$'
  and not exists (
    select 1 from public.incident_reports r
    where r.reporter_id = (select auth.uid())
      and split_part(objects.name, '.', 1) =
        r.reporter_id::text || '/' || replace(r.id::text, '-', '')
  )
);

alter policy incident_images_update_draft on storage.objects using (
  bucket_id = 'incident-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and not exists (
    select 1 from public.incident_reports r
    where r.reporter_id = (select auth.uid())
      and split_part(objects.name, '.', 1) =
        r.reporter_id::text || '/' || replace(r.id::text, '-', '')
  )
) with check (
  bucket_id = 'incident-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.](png|jpg)$'
  and not exists (
    select 1 from public.incident_reports r
    where r.reporter_id = (select auth.uid())
      and split_part(objects.name, '.', 1) =
        r.reporter_id::text || '/' || replace(r.id::text, '-', '')
  )
);

alter policy uth_incident_images_staff_read on storage.objects using (
  bucket_id = 'incident-images'
  and exists (
    select 1 from public.incident_reports i
    where objects.name in (
      i.reporter_id::text || '/' || replace(i.id::text, '-', '') || '.jpg',
      i.reporter_id::text || '/' || replace(i.id::text, '-', '') || '.png'
    )
    and (
      public.uth_incident_actor_role() = 'admin'
      or (public.uth_incident_actor_role() = 'technician'
        and i.approved_at is not null
        and (i.assigned_to = (select auth.uid()) or (i.assigned_to is null and i.status::text = 'open')))
    )
  )
);

-- Preserve the live validation and authorization logic while updating file lookup.
do $migration$
declare
  definition text;
  updated text;
begin
  definition := pg_get_functiondef('private.validate_incident_submission()'::regprocedure);
  updated := replace(definition,
    $old$o.name=new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.png'$old$,
    $new$o.name in (
      new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.jpg',
      new.reporter_id::text || '/' || replace(new.id::text,'-','') || '.png'
    )$new$);
  if updated = definition then raise exception 'Unexpected incident validation definition'; end if;
  execute updated;

  definition := pg_get_functiondef('public.incident_evidence_path(uuid)'::regprocedure);
  updated := replace(definition,
    $old$return incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.png';$old$,
    $new$return (
      select o.name from storage.objects o
      where o.bucket_id = 'incident-images'
        and o.name in (
          incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.jpg',
          incident.reporter_id::text || '/' || replace(incident.id::text, '-', '') || '.png'
        )
      order by (right(o.name, 4) = '.jpg') desc
      limit 1
    );$new$);
  if updated = definition then raise exception 'Unexpected incident evidence lookup definition'; end if;
  execute updated;
end
$migration$;
