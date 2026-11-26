alter table public.app_notifications
  add column maintenance_proposal_id uuid
  references public.maintenance_proposals(id) on delete set null;

create index app_notifications_maintenance_proposal_idx
  on public.app_notifications (maintenance_proposal_id)
  where maintenance_proposal_id is not null;

create function private.notify_maintenance_proposal_decision()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  asset_name text;
begin
  select coalesce(
    (select name from public.rooms where id = new.room_id),
    (select name from public.equipment where id = new.equipment_id),
    'Tài sản'
  ) into asset_name;

  insert into public.app_notifications (recipient_id, maintenance_proposal_id, title, message)
  values (
    new.proposer_id,
    new.id,
    case new.status when 'approved' then 'Đề xuất bảo trì đã được duyệt'
         else 'Đề xuất bảo trì bị từ chối' end,
    'Đề xuất bảo trì “' || asset_name || '” ' ||
    case new.status when 'approved' then 'đã được duyệt.' else 'đã bị từ chối.' end
  );
  return new;
end;
$$;

revoke all on function private.notify_maintenance_proposal_decision()
  from public, anon, authenticated;

create trigger notify_maintenance_proposal_decision
after update of status on public.maintenance_proposals
for each row
when (old.status = 'pending' and new.status in ('approved','rejected'))
execute function private.notify_maintenance_proposal_decision();

notify pgrst, 'reload schema';
