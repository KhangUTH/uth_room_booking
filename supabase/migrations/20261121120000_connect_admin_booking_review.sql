create or replace view public.uth_admin_bookings with (security_barrier = true) as
select b.id, b.id::text as booking_code, b.status, b.start_time, b.end_time, b.created_at,
       b.purpose, b.student_count, b.room_id, b.equipment_id,
       coalesce(nullif(trim(p.full_name), ''), p.email) as requester_name,
       p.role::text as requester_role, r.name as room_name, e.name as equipment_name,
       section.code as teaching_section_code, section.name as teaching_section_name
from public.bookings b
left join public.profiles p on p.id = b.user_id
left join public.rooms r on r.id = b.room_id
left join public.equipment e on e.id = b.equipment_id
left join public.teaching_sections section on section.id = b.teaching_section_id
where (select public.uth_admin_profile_read_allowed());

revoke all on public.uth_admin_bookings from public, anon, authenticated;
grant select on public.uth_admin_bookings to authenticated;

create or replace function public.uth_admin_decide_booking(booking_id uuid, decision text)
returns void
language plpgsql security definer
set search_path = ''
as $$
declare
  booking public.bookings%rowtype;
begin
  if not (select public.uth_admin_profile_read_allowed()) then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  if decision is null or decision not in ('approved', 'rejected') then
    raise exception 'Invalid booking decision' using errcode = '23514';
  end if;

  select b.* into booking
  from public.bookings b
  where b.id = booking_id and b.status = 'pending'
  for update;
  if not found then
    raise exception 'Booking is no longer pending' using errcode = 'P0002';
  end if;

  if decision = 'approved' then
    -- Keep the asset status stable until the decision commits.
    if booking.room_id is not null then
      perform 1 from public.rooms r
      where r.id = booking.room_id and r.is_active and not r.is_archived
      for share;
    else
      perform 1 from public.equipment e
      where e.id = booking.equipment_id and e.room_id is null and e.status = 'available'
      for share;
    end if;
    if not found then
      raise exception 'booking_asset_unavailable' using errcode = '23514';
    end if;
    if booking.start_time <= clock_timestamp() then
      raise exception 'booking_already_started' using errcode = '23514';
    end if;
  end if;

  update public.bookings
  set status = decision::public.booking_status
  where id = booking.id;
end;
$$;

revoke all on function public.uth_admin_decide_booking(uuid, text) from public, anon, authenticated;
grant execute on function public.uth_admin_decide_booking(uuid, text) to authenticated;

notify pgrst, 'reload schema';
