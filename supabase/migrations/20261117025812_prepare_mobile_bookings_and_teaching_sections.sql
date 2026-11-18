create table public.teaching_sections (
 id uuid primary key default gen_random_uuid(),
 lecturer_id uuid not null references public.profiles(id),
 code text not null check (length(trim(code)) > 0),
 name text not null check (length(trim(name)) > 0),
 unique (lecturer_id, code)
);
alter table public.teaching_sections enable row level security;
revoke all on public.teaching_sections from public, anon, authenticated;
grant select on public.teaching_sections to authenticated;
grant all on public.teaching_sections to service_role;
create policy teaching_sections_read_own on public.teaching_sections for select to authenticated
using (lecturer_id = (select auth.uid()) and exists (
 select 1 from public.profiles p where p.id = lecturer_id and p.role = 'teacher' and p.is_active
));

alter table public.bookings add column student_count integer,
 add column teaching_section_id uuid references public.teaching_sections(id),
 add constraint bookings_one_asset check (num_nonnulls(room_id, equipment_id) = 1);

drop policy "bookings: xem" on public.bookings;
drop policy "bookings: staff cập nhật" on public.bookings;
drop policy "bookings: tạo" on public.bookings;
drop policy "bookings: huỷ lịch của mình" on public.bookings;
revoke all on public.bookings from public, anon, authenticated;
grant select on public.bookings to authenticated;
grant insert (room_id,equipment_id,start_time,end_time,student_count,teaching_section_id), update (status) on public.bookings to authenticated;
create policy bookings_mobile_read_own on public.bookings for select to authenticated
using (user_id = (select auth.uid()) and exists (
 select 1 from public.profiles p where p.id = user_id and p.is_active and p.role in ('student','teacher')
));
create policy bookings_mobile_insert_own on public.bookings for insert to authenticated
with check (status = 'pending' and user_id = (select auth.uid()) and exists (
 select 1 from public.profiles p where p.id = user_id and p.is_active and p.role in ('student','teacher')
));
create policy bookings_mobile_cancel_pending on public.bookings for update to authenticated
using (status = 'pending' and user_id = (select auth.uid()) and exists (
 select 1 from public.profiles p where p.id = user_id and p.is_active and p.role in ('student','teacher')
))
with check (status = 'cancelled' and user_id = (select auth.uid()));

create schema if not exists private;
create function private.validate_mobile_booking()
returns trigger language plpgsql set search_path = '' as $$
declare requester_role public.user_role; room_capacity integer;
begin
 select p.role into requester_role from public.profiles p where p.id = new.user_id and p.is_active;
 if requester_role is null or requester_role not in ('student','teacher') or new.status <> 'pending' then
   raise exception 'Invalid booking requester or status' using errcode = '23514';
 end if;
 if new.start_time <= statement_timestamp() or
    ((new.start_time at time zone 'Asia/Ho_Chi_Minh')::time,
     (new.end_time at time zone 'Asia/Ho_Chi_Minh')::time)
      not in ((time '07:00',time '09:00'),(time '09:30',time '11:30'),(time '13:00',time '15:00'),(time '15:30',time '17:30')) or
    (new.start_time at time zone 'Asia/Ho_Chi_Minh')::date <> (new.end_time at time zone 'Asia/Ho_Chi_Minh')::date then
   raise exception 'Invalid booking slot' using errcode = '23514';
 end if;
 if new.room_id is not null then
   select r.capacity into room_capacity from public.rooms r where r.id = new.room_id and r.is_active and not r.is_archived;
   if room_capacity is null then raise exception 'Room unavailable' using errcode = '23514'; end if;
   if requester_role = 'student' then
     if new.student_count is null or new.student_count not between 10 and room_capacity or new.teaching_section_id is not null then
       raise exception 'Invalid student group size' using errcode = '23514';
     end if;
   elsif new.student_count is not null or not exists (select 1 from public.teaching_sections s where s.id = new.teaching_section_id and s.lecturer_id = new.user_id) then
     raise exception 'Teaching section not assigned' using errcode = '23514';
   end if;
 elsif new.student_count is not null or new.teaching_section_id is not null or not exists (
   select 1 from public.equipment e where e.id = new.equipment_id and e.room_id is null and e.status = 'available'
 ) then
   raise exception 'Equipment unavailable or invalid booking details' using errcode = '23514';
 end if;
 return new;
end $$;
revoke all on function private.validate_mobile_booking() from public, anon, authenticated;
create trigger validate_mobile_booking before insert on public.bookings
for each row execute function private.validate_mobile_booking();
