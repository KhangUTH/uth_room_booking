-- Apply once after the active-admin helper from 03 is available.
begin;

create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  subject text not null check (length(trim(subject)) between 1 and 250),
  message text not null check (length(trim(message)) > 0),
  reply text check (length(trim(reply)) between 1 and 2000),
  created_at timestamptz not null default now()
);

alter table public.support_requests enable row level security;
revoke all on public.support_requests from public, anon, authenticated;
grant select, update (reply) on public.support_requests to authenticated;
grant select, insert, update, delete on public.support_requests to service_role;

create policy uth_admin_support_read on public.support_requests for select to authenticated
using ((select public.uth_admin_profile_read_allowed()));

create policy uth_admin_support_reply on public.support_requests for update to authenticated
using (reply is null and (select public.uth_admin_profile_read_allowed()))
with check (reply is not null and (select public.uth_admin_profile_read_allowed()));

notify pgrst, 'reload schema';
commit;
