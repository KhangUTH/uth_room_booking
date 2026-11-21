alter table public.rooms add column allows_teacher_booking boolean not null default true;
update public.rooms set allows_teacher_booking = false where name = 'Phòng thư viện' and not is_archived;
create function private.enforce_teacher_room_access()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.room_id is not null and new.status in ('pending', 'approved')
    and exists (select 1 from public.profiles p where p.id = new.user_id and p.role = 'teacher')
    and exists (select 1 from public.rooms r where r.id = new.room_id and not r.allows_teacher_booking)
  then
    raise exception 'teacher_room_not_allowed' using errcode = '23514';
  end if;
  return new;
end $$;
revoke all on function private.enforce_teacher_room_access() from public, anon, authenticated;
create trigger enforce_teacher_room_access
before insert or update of room_id, user_id, status on public.bookings
for each row execute function private.enforce_teacher_room_access();
