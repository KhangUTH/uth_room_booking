create table private.incident_photo_cleanup_claims (
  path text primary key,
  expires_at timestamptz not null
);

create function private.guard_incident_photo_cleanup()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  stem text := new.reporter_id::text || '/' || replace(new.id::text, '-', '');
begin
  perform pg_advisory_xact_lock(hashtextextended(stem, 5274));
  if exists (
    select from private.incident_photo_cleanup_claims c
    where c.path in (stem || '.jpg', stem || '.png') and c.expires_at > now()
  ) then
    raise exception 'incident_photo_cleanup_in_progress' using errcode = '55000';
  end if;
  return new;
end
$$;

revoke all on function private.guard_incident_photo_cleanup() from public, anon, authenticated;
create trigger guard_incident_photo_cleanup
before insert on public.incident_reports
for each row when (new.has_photo)
execute function private.guard_incident_photo_cleanup();

create function public.claim_expired_incident_photos(cleanup_token text)
returns setof text language plpgsql security definer set search_path = ''
as $$
declare
  photo record;
  claimed text;
begin
  if cleanup_token is null or not exists (
    select from vault.decrypted_secrets
    where name = 'uth_incident_cleanup_token' and decrypted_secret = cleanup_token
  ) then
    raise exception 'Invalid cleanup token' using errcode = '42501';
  end if;
  delete from private.incident_photo_cleanup_claims where expires_at <= now();
  for photo in
    select o.name, split_part(o.name, '.', 1) as stem
    from storage.objects o
    where o.bucket_id = 'incident-images'
      and o.name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}[.](jpg|png)$'
      and coalesce(o.updated_at, o.created_at) < now() - interval '24 hours'
      and not exists (
        select from public.incident_reports r
        where split_part(o.name, '.', 1) = r.reporter_id::text || '/' || replace(r.id::text, '-', '')
      )
    order by coalesce(o.updated_at, o.created_at), o.name
    limit 50
  loop
    perform pg_advisory_xact_lock(hashtextextended(photo.stem, 5274));
    if exists (
      select from storage.objects o where o.bucket_id = 'incident-images'
        and o.name = photo.name
        and coalesce(o.updated_at, o.created_at) < now() - interval '24 hours'
    ) and not exists (
      select from public.incident_reports r
      where photo.stem = r.reporter_id::text || '/' || replace(r.id::text, '-', '')
    ) then
      insert into private.incident_photo_cleanup_claims(path, expires_at)
      values (photo.name, now() + interval '15 minutes')
      on conflict do nothing returning path into claimed;
      if found then return next claimed; end if;
    end if;
  end loop;
end
$$;

-- The job stays behind a service-role-only RPC; the supplied token is checked in Vault.
revoke all on function public.claim_expired_incident_photos(text) from public, anon, authenticated;
grant execute on function public.claim_expired_incident_photos(text) to service_role;

-- Retire client-side removal so only the scheduled worker can acquire a cleanup claim.
drop policy incident_images_delete_expired_draft on storage.objects;
