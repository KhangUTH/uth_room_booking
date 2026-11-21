create policy uth_incidents_reporter_read_own
on public.incident_reports
as permissive
for select
to authenticated
using (
  (select public.uth_incident_actor_role()) in ('student', 'teacher')
  and reporter_id = (select auth.uid())
);
