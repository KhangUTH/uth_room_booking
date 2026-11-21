-- Keep incident visibility aligned with the technician work queue.
drop policy if exists "incident_reports: xem" on public.incident_reports;

-- The existing read policies serve the app, and active admins manage the catalog.
drop policy if exists "rooms: technician quản lý" on public.rooms;
drop policy if exists "equipment: technician quản lý" on public.equipment;
