alter table public.profiles add column phone text
  check (phone is null or char_length(phone) between 1 and 32);

grant update (phone) on public.profiles to authenticated;

create policy profiles_update_own_phone on public.profiles
for update to authenticated
using (id = (select auth.uid()) and is_active)
with check (id = (select auth.uid()) and is_active);

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

create function public.list_expired_incident_photos()
returns setof text
language sql stable
security invoker
set search_path = ''
as $function$
  select o.name
  from storage.objects o
  where o.bucket_id = 'incident-images'
    and o.name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.](jpg|png)$'
    and (storage.foldername(o.name))[1] = (select auth.uid())::text
    and coalesce(o.updated_at, o.created_at) < statement_timestamp() - interval '24 hours'
    and not exists (
      select from public.incident_reports r
      where r.reporter_id = (select auth.uid())
        and split_part(o.name, '.', 1) =
          r.reporter_id::text || '/' || replace(r.id::text, '-', '')
    )
  order by coalesce(o.updated_at, o.created_at), o.name
  limit 50;
$function$;

revoke all on function public.list_expired_incident_photos() from public, anon, authenticated;
grant execute on function public.list_expired_incident_photos() to authenticated;
