create function private.validate_incident_teaching_section()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.course_section is not null and not exists (
    select 1 from public.teaching_sections s
    where s.lecturer_id = new.reporter_id
      and new.course_section = s.code || ' · ' || s.name
  ) then
    raise exception 'incident_teaching_section_not_assigned' using errcode='23514';
  end if;
  return new;
end $$;
revoke all on function private.validate_incident_teaching_section() from public, anon, authenticated;
create trigger validate_incident_teaching_section before insert on public.incident_reports
for each row execute function private.validate_incident_teaching_section();
