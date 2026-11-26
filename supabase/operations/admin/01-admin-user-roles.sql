-- STEP 1: Fix the missing role dropdown function only.
-- Requires the logged-in admin to already be able to read their own profile.
-- Does not change table grants, data, RLS or policies, or is_active_admin().
-- An existing no-argument function is preserved, not replaced.
begin;

do $migration$
begin
  if pg_catalog.to_regprocedure('public.admin_user_roles()') is not null then
    raise notice 'admin_user_roles() already exists; left unchanged. Inspect its definition if the application still reports an error.';
  else
    execute $function$
      create function public.admin_user_roles()
      returns text[]
      language plpgsql stable security invoker
      set search_path = ''
      as $body$
      begin
        if not exists (
          select 1 from public.profiles
          where id = (select auth.uid())
            and role::text = 'admin'
            and is_active = true
        ) then
          raise exception 'Admin access required' using errcode = '42501';
        end if;

        return array(
          select enum_value::text
          from pg_catalog.unnest(pg_catalog.enum_range(null::public.user_role)) as role_values(enum_value)
        );
      end;
      $body$;
    $function$;

    revoke all on function public.admin_user_roles() from public, anon;
    grant execute on function public.admin_user_roles() to authenticated;
  end if;
end;
$migration$;

notify pgrst, 'reload schema';
commit;
