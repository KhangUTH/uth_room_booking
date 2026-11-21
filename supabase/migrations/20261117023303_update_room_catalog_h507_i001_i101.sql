alter table public.rooms add column is_archived boolean not null default false;
update public.rooms set is_archived = true, is_active = false where name = 'Phòng máy H004';
insert into public.rooms (name, location, capacity, is_active) values
  ('Phòng máy H507', 'Tòa H, Tầng 5', 32, true),
  ('Phòng máy I001', 'Tòa I', 32, false),
  ('Phòng máy I101', 'Tòa I', 32, false);
update public.rooms set capacity = case when name = 'Phòng thư viện' then 20 else 32 end where not is_archived;
