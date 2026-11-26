create policy uth_admin_bookings_broadcast_read
on realtime.messages
for select to authenticated
using (
  extension = 'broadcast'
  and (select realtime.topic()) = 'uth-admin-bookings'
  and (select public.uth_admin_profile_read_allowed())
);

create function private.broadcast_admin_booking_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('new_booking', tg_op = 'INSERT' and new.status = 'pending'),
    'booking_changed',
    'uth-admin-bookings',
    true
  );
  return null;
exception when others then
  raise warning 'Admin booking broadcast failed (SQLSTATE %)', sqlstate;
  return null;
end;
$$;

revoke all on function private.broadcast_admin_booking_change()
  from public, anon, authenticated;

create trigger broadcast_admin_booking_change
after insert or update or delete on public.bookings
for each row execute function private.broadcast_admin_booking_change();
