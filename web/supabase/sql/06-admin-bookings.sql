-- Historical SQL Editor setup. Use 20261121120000_connect_admin_booking_review.sql
-- in the shared supabase/migrations directory for current installations and upgrades.
begin;

create view public.uth_admin_bookings with (security_barrier = true) as
select b.id, b.id::text as booking_code, b.status, b.start_time, b.end_time, b.created_at,
       b.purpose, b.student_count, b.room_id, b.equipment_id,
       coalesce(nullif(trim(p.full_name), ''), p.email) as requester_name,
       p.role::text as requester_role, r.name as room_name, e.name as equipment_name
from public.bookings b
left join public.profiles p on p.id = b.user_id
left join public.rooms r on r.id = b.room_id
left join public.equipment e on e.id = b.equipment_id
where (select public.uth_admin_profile_read_allowed());

revoke all on public.uth_admin_bookings from public, anon, authenticated;
grant select on public.uth_admin_bookings to authenticated;

create function public.uth_admin_decide_booking(booking_id uuid, decision text)
returns void
language plpgsql security definer
set search_path = ''
as $$
begin
  if not (select public.uth_admin_profile_read_allowed()) then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  if decision is null or decision not in ('approved', 'rejected') then
    raise exception 'Invalid booking decision' using errcode = '23514';
  end if;

  update public.bookings
  set status = decision::public.booking_status
  where id = booking_id and status = 'pending';
  if not found then
    raise exception 'Booking is no longer pending' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.uth_admin_decide_booking(uuid, text) from public, anon, authenticated;
grant execute on function public.uth_admin_decide_booking(uuid, text) to authenticated;

notify pgrst, 'reload schema';
commit;
