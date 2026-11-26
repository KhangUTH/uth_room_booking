create table public.maintenance_proposals (
  id uuid primary key default gen_random_uuid(),
  proposer_id uuid not null default auth.uid() references public.profiles(id),
  room_id uuid references public.rooms(id),
  equipment_id uuid references public.equipment(id),
  reason text not null check (length(trim(reason)) between 1 and 2000),
  scheduled_date date,
  slot_index smallint check (slot_index between 0 and 3),
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  created_at timestamptz not null default now(),
  check (num_nonnulls(room_id,equipment_id) = 1),
  check ((scheduled_date is null) = (slot_index is null))
);

create index maintenance_proposals_owner_created_idx
  on public.maintenance_proposals (proposer_id, created_at desc, id);
create index maintenance_proposals_created_idx
  on public.maintenance_proposals (created_at desc, id);

alter table public.maintenance_proposals enable row level security;
revoke all on public.maintenance_proposals from public, anon, authenticated;
grant select, insert (room_id,equipment_id,reason,scheduled_date,slot_index),
  update (status) on public.maintenance_proposals to authenticated;

create policy maintenance_proposals_read on public.maintenance_proposals
  for select to authenticated using (
    (select public.uth_incident_actor_role()) = 'admin'
    or ((select public.uth_incident_actor_role()) = 'technician' and proposer_id = (select auth.uid()))
  );

create policy maintenance_proposals_create on public.maintenance_proposals
  for insert to authenticated with check (
    (select public.uth_incident_actor_role()) = 'technician'
    and proposer_id = (select auth.uid()) and status = 'pending'
    and (room_id is null or exists (select from public.rooms r where r.id = room_id and not r.is_archived))
  );

create policy maintenance_proposals_cancel on public.maintenance_proposals
  for update to authenticated
  using ((select public.uth_incident_actor_role()) = 'technician'
    and proposer_id = (select auth.uid()) and status = 'pending')
  with check ((select public.uth_incident_actor_role()) = 'technician'
    and proposer_id = (select auth.uid()) and status = 'cancelled');

create policy maintenance_proposals_decide on public.maintenance_proposals
  for update to authenticated
  using ((select public.uth_incident_actor_role()) = 'admin' and status = 'pending')
  with check ((select public.uth_incident_actor_role()) = 'admin' and status in ('approved','rejected'));

create trigger broadcast_admin_data_change
after insert or update or delete on public.maintenance_proposals
for each statement execute function private.broadcast_admin_data_change();
