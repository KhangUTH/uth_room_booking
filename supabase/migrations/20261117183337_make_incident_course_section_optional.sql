do $migration$
declare
  original_definition text := pg_get_functiondef('private.validate_incident_submission()'::regprocedure);
  updated_definition text;
begin
  updated_definition := replace(original_definition,
    'or (new.needs_support and coalesce(length(trim(new.course_section)),0)=0)', '');
  if updated_definition = original_definition then
    raise exception 'Unexpected incident validation definition';
  end if;
  execute updated_definition;
end
$migration$;
