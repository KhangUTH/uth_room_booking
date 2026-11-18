-- Danh mục tài sản để thử app trên môi trường sạch.
insert into public.rooms (name, location, capacity, is_active, is_archived, allows_teacher_booking)
select item.*
from (values
  ('Phòng máy H003', 'Toà H, Tầng trệt', 32, true, false, true),
  ('Phòng máy H004', 'Toà H, Tầng trệt', 32, false, true, true),
  ('Phòng máy H509', 'Toà H, Tầng 5', 32, true, false, true),
  ('Phòng thư viện', 'Toà K, Tầng 1', 20, true, false, false)
) as item(name, location, capacity, is_active, is_archived, allows_teacher_booking)
where not exists (select from public.rooms r where r.name = item.name);

update public.rooms set location = 'Tòa I, Tầng trệt' where name = 'Phòng máy I001';
update public.rooms set location = 'Tòa I, Tầng 1' where name = 'Phòng máy I101';

insert into public.equipment (name, location)
select item.name, 'H005 - Trung Tâm Thông Tin Thư Viện'
from (values
  ('Bàn phím A4Tech KR-83'),
  ('Chuột Logitech M331 Silent Plus'),
  ('Micro TOA DM-1100'),
  ('Ổ cắm Điện Quang ĐQ 003A-04'),
  ('Tai nghe Logitech H340')
) as item(name)
where not exists (
  select from public.equipment e where e.name = item.name and e.room_id is null
);
