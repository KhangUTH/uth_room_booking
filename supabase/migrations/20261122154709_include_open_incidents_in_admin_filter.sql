CREATE OR REPLACE FUNCTION public.admin_incident_reports(page_number integer DEFAULT 1, search_text text DEFAULT ''::text, status_filter text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare result jsonb;
begin
  if public.uth_incident_actor_role() is distinct from 'admin' then
    raise exception 'Active admin required' using errcode = '42501';
  end if;
  if page_number < 1 or page_number > 1000000 then raise exception 'Invalid page'; end if;
  with matching as (
    select i.id, i.created_at from public.incident_reports i
    where (search_text = '' or i.title ilike '%' || search_text || '%'
      or i.report_number::text = regexp_replace(search_text, '^#?SC[- ]*', '', 'i'))
    and (status_filter = ''
      or (status_filter = 'pending' and i.status::text = 'open' and i.approved_at is null)
      or (status_filter = 'approved' and i.status::text = 'open' and i.approved_at is not null)
      or (status_filter in ('open','in_progress','resolved','cancelled') and i.status::text = status_filter))
  ), paged as (
    select * from matching order by created_at desc, id limit 10 offset (page_number - 1) * 10
  ) select jsonb_build_object('count', (select count(*) from matching),
      'rows', coalesce((select jsonb_agg(public.uth_incident_payload(id) order by created_at desc, id) from paged), '[]'::jsonb))
    into result;
  return result;
end
$function$;
