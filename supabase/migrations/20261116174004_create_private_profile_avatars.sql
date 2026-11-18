insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('profile-avatars', 'profile-avatars', false, 2097152, array['image/png']);
create policy profile_avatar_select on storage.objects for select to authenticated using (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
create policy profile_avatar_insert on storage.objects for insert to authenticated with check (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
create policy profile_avatar_update on storage.objects for update to authenticated using (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png') with check (bucket_id = 'profile-avatars' and name = (select auth.uid())::text || '/avatar.png');
