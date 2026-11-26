create function private.broadcast_admin_data_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('source', tg_table_name),
    'admin_data_changed',
    'uth-admin-bookings',
    true
  );
  return null;
exception when others then
  raise warning 'Admin data broadcast failed (SQLSTATE %)', sqlstate;
  return null;
end;
$$;

revoke all on function private.broadcast_admin_data_change()
  from public, anon, authenticated;

do $$
declare
  source_table text;
begin
  foreach source_table in array array['incident_reports', 'profiles', 'rooms', 'equipment', 'support_requests']
  loop
    execute format(
      'create trigger broadcast_admin_data_change after insert or update or delete on public.%I for each statement execute function private.broadcast_admin_data_change()',
      source_table
    );
  end loop;
end;
$$;
