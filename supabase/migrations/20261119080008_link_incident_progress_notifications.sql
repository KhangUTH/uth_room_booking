alter table public.app_notifications
  add column incident_report_id uuid references public.incident_reports(id) on delete set null;

create index app_notifications_incident_report_idx
  on public.app_notifications (incident_report_id)
  where incident_report_id is not null;

create or replace function private.notify_incident_progress()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  insert into public.app_notifications (recipient_id, incident_report_id, title, message)
  values (
    new.reporter_id,
    new.id,
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

-- Link older notices only when exactly one report matches.
with matches as (
  select n.id, min(i.id::text)::uuid as report_id
  from public.app_notifications n
  join public.incident_reports i
    on i.reporter_id = n.recipient_id
    and i.created_at <= n.created_at
    and n.message = 'Báo cáo “' || i.title || '” ' ||
      case n.title
        when 'Kỹ thuật viên đã nhận công việc' then 'đã được tiếp nhận và đang xử lý.'
        when 'Kỹ thuật viên đã hoàn tất công việc' then 'đã được xử lý xong. Bạn có thể xem lại trong Báo cáo của tôi.'
      end
  where n.incident_report_id is null and n.booking_id is null
    and n.title in ('Kỹ thuật viên đã nhận công việc', 'Kỹ thuật viên đã hoàn tất công việc')
  group by n.id
  having count(*) = 1
)
update public.app_notifications n
set incident_report_id = matches.report_id
from matches
where n.id = matches.id;
