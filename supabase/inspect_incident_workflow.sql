-- Read-only. Run in the real Supabase SQL Editor before applying the migration.
-- A single result cell contains every section. Copy/export the complete cell;
-- screenshots of the grants alone do not include trigger function bodies.
-- Never run the local test fixtures in the live project.
select jsonb_pretty(jsonb_build_object(
  'columns', (select jsonb_agg(to_jsonb(c) order by ordinal_position) from (
    select column_name, data_type, udt_name, column_default, is_nullable, ordinal_position
    from information_schema.columns where table_schema = 'public' and table_name = 'incident_reports'
  ) c),
  'triggers', coalesce((select jsonb_agg(jsonb_build_object(
    'name', t.tgname, 'definition', pg_get_triggerdef(t.oid),
    'function_name', p.proname, 'function_definition', pg_get_functiondef(p.oid)))
    from pg_trigger t join pg_proc p on p.oid = t.tgfoid
    where t.tgrelid = 'public.incident_reports'::regclass and not t.tgisinternal), '[]'::jsonb),
  'policies', (select jsonb_agg(to_jsonb(p)) from (
    select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
    from pg_policies where (schemaname = 'public' and tablename = 'incident_reports')
      or (schemaname = 'storage' and tablename = 'objects')
  ) p),
  'table_grants', (select jsonb_agg(to_jsonb(g)) from (
    select grantee, privilege_type from information_schema.role_table_grants
    where table_schema = 'public' and table_name = 'incident_reports'
  ) g),
  'column_grants', (select jsonb_agg(to_jsonb(g)) from (
    select grantee, column_name, privilege_type from information_schema.role_column_grants
    where table_schema = 'public' and table_name = 'incident_reports' and grantee = 'authenticated'
  ) g)
)) as incident_workflow_inspection;
