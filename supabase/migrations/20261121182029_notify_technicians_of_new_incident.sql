create function private.notify_technicians_of_new_incident()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.app_notifications (recipient_id, incident_report_id, title, message)
  select id, new.id, 'Có báo cáo sự cố mới', 'Báo cáo “' || new.title || '” đang chờ tiếp nhận.'
  from public.profiles
  where role = 'technician' and is_active;
  return new;
end;
$$;

revoke all on function private.notify_technicians_of_new_incident()
  from public, anon, authenticated;

create trigger notify_technicians_of_new_incident
after insert on public.incident_reports
for each row
when (new.status = 'open' and new.assigned_to is null)
execute function private.notify_technicians_of_new_incident();
