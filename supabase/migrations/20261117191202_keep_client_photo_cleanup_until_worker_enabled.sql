create policy incident_images_delete_expired_draft on storage.objects
for delete to authenticated
using (
  bucket_id = 'incident-images'
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.](jpg|png)$'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and coalesce(updated_at, created_at) < statement_timestamp() - interval '24 hours'
  and not exists (
    select from public.incident_reports r
    where r.reporter_id = (select auth.uid())
      and split_part(objects.name, '.', 1) =
        r.reporter_id::text || '/' || replace(r.id::text, '-', '')
  )
);
