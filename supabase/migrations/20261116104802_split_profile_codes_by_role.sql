alter table public.profiles
  add column lecturer_code text,
  add column employee_code text;

update public.profiles
set lecturer_code = case when role = 'teacher' then student_code end,
    employee_code = case when role = 'technician' then student_code end,
    student_code = null
where role in ('teacher', 'technician') and student_code is not null;

alter table public.profiles add constraint profiles_code_matches_role check (
  (student_code is null or role = 'student') and
  (lecturer_code is null or role = 'teacher') and
  (employee_code is null or role = 'technician')
);
create unique index profiles_lecturer_code_key on public.profiles (lecturer_code)
  where lecturer_code is not null;
create unique index profiles_employee_code_key on public.profiles (employee_code)
  where employee_code is not null;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare
  account_role public.user_role := coalesce(
    nullif(new.raw_app_meta_data->>'app_role', '')::public.user_role, 'student'
  );
  legacy_code text := nullif(btrim(new.raw_user_meta_data->>'student_code'), '');
begin
  if new.email is null or lower(new.email) not like '%@ut.edu.vn' then
    raise exception 'Chỉ cho phép email @ut.edu.vn (nhận: %)', new.email;
  end if;
  insert into public.profiles
    (id, email, full_name, role, student_code, lecturer_code, employee_code)
  values (
    new.id, lower(new.email), new.raw_user_meta_data->>'full_name', account_role,
    case when account_role = 'student' then legacy_code end,
    case when account_role = 'teacher' then coalesce(
      nullif(btrim(new.raw_user_meta_data->>'lecturer_code'), ''), legacy_code
    ) end,
    case when account_role = 'technician' then coalesce(
      nullif(btrim(new.raw_user_meta_data->>'employee_code'), ''), legacy_code
    ) end
  );
  return new;
end;
$function$;
