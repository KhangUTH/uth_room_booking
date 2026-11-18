create function private.notify_incident_claimed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.app_notifications (recipient_id, title, message)
  values (
    new.reporter_id,
    'Kỹ thuật viên đã nhận công việc',
    'Báo cáo “' || new.title || '” đã được tiếp nhận và đang xử lý.'
  );
  return new;
end;
$function$;

revoke all on function private.notify_incident_claimed() from public, anon, authenticated;

create trigger notify_incident_claimed
after update of status on public.incident_reports
for each row
when (
  old.status = 'open'
  and new.status = 'in_progress'
  and new.approved_at is not null
  and new.assigned_to is not null
)
execute function private.notify_incident_claimed();
