alter function private.notify_incident_claimed() rename to notify_incident_progress;

create or replace function private.notify_incident_progress()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.app_notifications (recipient_id, title, message)
  values (
    new.reporter_id,
    case new.status
      when 'resolved' then 'Kỹ thuật viên đã hoàn tất công việc'
      else 'Kỹ thuật viên đã nhận công việc'
    end,
    'Báo cáo “' || new.title || '” ' ||
      case new.status
        when 'resolved' then 'đã được xử lý xong. Bạn có thể xem lại trong Báo cáo của tôi.'
        else 'đã được tiếp nhận và đang xử lý.'
      end
  );
  return new;
end;
$function$;

drop trigger notify_incident_claimed on public.incident_reports;

create trigger notify_incident_progress
after update of status on public.incident_reports
for each row
when (
  new.assigned_to is not null and (
    (old.status = 'open' and new.status = 'in_progress')
    or (old.status = 'in_progress' and new.status = 'resolved')
  )
)
execute function private.notify_incident_progress();
