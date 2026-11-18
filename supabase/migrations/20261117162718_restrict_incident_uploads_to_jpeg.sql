update storage.buckets
set allowed_mime_types = array['image/jpeg']
where id = 'incident-images';

do $migration$
declare
  source_policy record;
  jpeg_check text;
begin
  for source_policy in
    select policyname, with_check from pg_policies
    where schemaname = 'storage' and tablename = 'objects'
      and policyname in ('incident_images_insert_own', 'incident_images_update_draft')
  loop
    jpeg_check := replace(source_policy.with_check, '[.](png|jpg)$', '[.]jpg$');
    if jpeg_check = source_policy.with_check then
      raise exception 'Unexpected attachment policy: %', source_policy.policyname;
    end if;
    execute format('alter policy %I on storage.objects with check (%s)',
      source_policy.policyname, jpeg_check);
  end loop;
end
$migration$;
