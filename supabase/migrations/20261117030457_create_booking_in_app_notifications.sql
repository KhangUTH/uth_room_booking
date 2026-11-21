create table public.app_notifications (
 id bigint generated always as identity primary key,
 recipient_id uuid not null references public.profiles(id) on delete cascade,
 booking_id uuid references public.bookings(id) on delete set null,
 title text not null,
 message text not null,
 created_at timestamptz not null default now(),
 is_read boolean not null default false,
 is_saved boolean not null default false
);
alter table public.app_notifications enable row level security;
revoke all on public.app_notifications from public, anon, authenticated;
grant select, update (is_read, is_saved) on public.app_notifications to authenticated;
grant all on public.app_notifications to service_role;
create index app_notifications_recipient_idx on public.app_notifications (recipient_id, id desc);
create index app_notifications_booking_idx on public.app_notifications (booking_id);
create policy app_notifications_read_own on public.app_notifications for select to authenticated
using (recipient_id = (select auth.uid()));
create policy app_notifications_update_own on public.app_notifications for update to authenticated
using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));

create function private.notify_booking_status()
returns trigger language plpgsql security definer set search_path = '' as $$
declare notification_title text; asset_name text;
begin
 if tg_op = 'UPDATE' and new.status is not distinct from old.status then return new; end if;
 notification_title := case new.status
   when 'pending' then 'Đã gửi đăng ký'
   when 'approved' then 'Đăng ký đã được duyệt'
   when 'rejected' then 'Đăng ký bị từ chối'
   when 'cancelled' then 'Đăng ký đã được hủy'
   when 'completed' then 'Đã hoàn thành lượt sử dụng'
 end;
 if new.room_id is not null then
   select r.name into asset_name from public.rooms r where r.id = new.room_id;
 else
   select e.name into asset_name from public.equipment e where e.id = new.equipment_id;
 end if;
 insert into public.app_notifications(recipient_id, booking_id, title, message)
 values (
   new.user_id, new.id, notification_title,
   coalesce(asset_name, 'Tài sản đăng ký') || ' · ' ||
   to_char(new.start_time at time zone 'Asia/Ho_Chi_Minh', 'HH24:MI DD/MM/YYYY')
 );
 return new;
end $$;
revoke all on function private.notify_booking_status() from public, anon, authenticated;
create trigger notify_booking_status after insert or update of status on public.bookings
for each row execute function private.notify_booking_status();
