alter table public.equipment add column if not exists location text;
update public.equipment set location = 'H005 - Trung Tâm Thông Tin Thư Viện'
where room_id is null and name in ('Ổ điện','Bàn phím A4Tech KR-83','Tai nghe Logitech H340','Chuột Logitech M331 Silent Plus','Micro TOA DM-1100');
