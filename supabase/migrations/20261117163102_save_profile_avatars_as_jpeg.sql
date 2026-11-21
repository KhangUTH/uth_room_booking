update storage.buckets
set allowed_mime_types = array['image/jpeg']
where id = 'profile-avatars';

alter policy profile_avatar_select on storage.objects using (
  bucket_id = 'profile-avatars'
  and name in (
    (select auth.uid())::text || '/avatar.jpg',
    (select auth.uid())::text || '/avatar.png'
  )
);

alter policy profile_avatar_insert on storage.objects with check (
  bucket_id = 'profile-avatars'
  and name = (select auth.uid())::text || '/avatar.jpg'
);

alter policy profile_avatar_update on storage.objects using (
  bucket_id = 'profile-avatars'
  and name = (select auth.uid())::text || '/avatar.jpg'
) with check (
  bucket_id = 'profile-avatars'
  and name = (select auth.uid())::text || '/avatar.jpg'
);
