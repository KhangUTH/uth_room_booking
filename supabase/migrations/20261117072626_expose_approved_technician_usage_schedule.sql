create function private.technician_usage_schedule(week_start date)
returns table (asset_name text, asset_location text, room_capacity integer, starts_at timestamptz, status public.booking_status)
language sql stable security definer set search_path='' as $$
  select coalesce(r.name,e.name), coalesce(r.location,e.location),
         coalesce(r.capacity,0), b.start_time, b.status
  from public.bookings b
  left join public.rooms r on r.id = b.room_id
  left join public.equipment e on e.id = b.equipment_id
  where exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.is_active and p.role = 'technician'
  )
  and b.status in ('approved','completed')
  and b.start_time >= (week_start::timestamp at time zone 'Asia/Ho_Chi_Minh')
  and b.start_time < ((week_start + 7)::timestamp at time zone 'Asia/Ho_Chi_Minh')
  order by b.start_time, coalesce(r.name,e.name);
$$;
revoke all on function private.technician_usage_schedule(date) from public, anon, authenticated;
grant execute on function private.technician_usage_schedule(date) to authenticated;
create function public.technician_usage_schedule(week_start date)
returns table (asset_name text, asset_location text, room_capacity integer, starts_at timestamptz, status public.booking_status)
language sql stable set search_path='' as $$
  select * from private.technician_usage_schedule(week_start);
$$;
revoke all on function public.technician_usage_schedule(date) from public, anon, authenticated;
grant execute on function public.technician_usage_schedule(date) to authenticated;
