-- READ ONLY: inspect incoming foreign keys before enabling room DELETE.
-- Run in Supabase SQL Editor. No data, grants, policies or constraints change.
select
  c.conrelid::regclass as referencing_table,
  c.conname as constraint_name,
  case c.confdeltype
    when 'a' then 'NO ACTION'
    when 'r' then 'RESTRICT'
    when 'c' then 'CASCADE'
    when 'n' then 'SET NULL'
    when 'd' then 'SET DEFAULT'
  end as on_delete,
  pg_catalog.pg_get_constraintdef(c.oid) as definition
from pg_catalog.pg_constraint c
where c.contype = 'f'
  and c.confrelid = 'public.rooms'::regclass
order by c.conrelid::regclass::text, c.conname;
