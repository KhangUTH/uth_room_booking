grant delete on public.maintenance_proposals to authenticated;

create policy maintenance_proposals_admin_delete
on public.maintenance_proposals
for delete to authenticated
using ((select public.uth_incident_actor_role()) = 'admin');
