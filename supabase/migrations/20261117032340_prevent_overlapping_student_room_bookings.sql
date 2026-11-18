create function private.prevent_student_room_overlap()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.room_id is null or new.status not in ('pending', 'approved')
    or not exists (select 1 from public.profiles p where p.id = new.user_id and p.role = 'student')
  then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended('student-room-booking:' || new.user_id::text, 0));
  if exists (
    select 1 from public.bookings b
    where b.user_id = new.user_id and b.id <> new.id
      and b.room_id is not null and b.status in ('pending', 'approved')
      and b.start_time < new.end_time and new.start_time < b.end_time
  ) then
    raise exception 'student_room_slot_conflict' using errcode = '23P01';
  end if;
  return new;
end $$;
revoke all on function private.prevent_student_room_overlap() from public, anon, authenticated;
create trigger prevent_student_room_overlap
before insert or update of status, room_id, user_id, start_time, end_time on public.bookings
for each row execute function private.prevent_student_room_overlap();
