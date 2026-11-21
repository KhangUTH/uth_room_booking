grant usage on schema private to authenticated;
create function private.mobile_busy_booking_slots(day date)
returns table (room_id uuid, equipment_id uuid, start_time timestamptz)
language sql stable security definer set search_path = '' as $$
select b.room_id,b.equipment_id,b.start_time from public.bookings b
where b.start_time >= (day::timestamp at time zone 'Asia/Ho_Chi_Minh')
and b.start_time < ((day + 1)::timestamp at time zone 'Asia/Ho_Chi_Minh')
and b.status in ('pending','approved')
and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.is_active and p.role in ('student','teacher'));
$$;
revoke all on function private.mobile_busy_booking_slots(date) from public,anon,authenticated;
grant execute on function private.mobile_busy_booking_slots(date) to authenticated;
create function public.mobile_busy_booking_slots(day date)
returns table (room_id uuid, equipment_id uuid, start_time timestamptz)
language sql stable set search_path = '' as $$
select * from private.mobile_busy_booking_slots(day);
$$;
revoke all on function public.mobile_busy_booking_slots(date) from public,anon,authenticated;
grant execute on function public.mobile_busy_booking_slots(date) to authenticated;
