create table private.mobile_push_devices (
  session_id uuid primary key references auth.sessions(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique
);
create index mobile_push_devices_recipient_idx
  on private.mobile_push_devices (recipient_id);

create table private.mobile_push_queue (
  id bigint generated always as identity primary key,
  notice_id bigint not null references public.app_notifications(id) on delete cascade,
  session_id uuid not null references private.mobile_push_devices(session_id) on delete cascade,
  created_at timestamptz not null default now(),
  available_at timestamptz not null default now(),
  attempt integer not null default 0
);
create index mobile_push_queue_available_idx on private.mobile_push_queue (available_at, id);
create index mobile_push_queue_session_idx on private.mobile_push_queue (session_id);
create index mobile_push_queue_notice_idx on private.mobile_push_queue (notice_id);

create function public.set_mobile_notification_token(device_token text)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  account_id uuid := auth.uid();
  active_session_id uuid := (auth.jwt() ->> 'session_id')::uuid;
begin
  if account_id is null or not exists (
    select 1 from auth.sessions s where s.id = active_session_id
      and s.user_id = account_id and (s.not_after is null or s.not_after > now())
  ) then
    raise exception 'Active session required' using errcode = '42501';
  end if;
  if device_token is null then
    delete from private.mobile_push_devices where session_id = active_session_id;
    return;
  end if;
  if length(device_token) not between 20 and 512 or device_token ~ '[[:space:]]' then
    raise exception 'Invalid registration token' using errcode = '22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(device_token, 10931));
  delete from private.mobile_push_devices where token = device_token and session_id <> active_session_id;
  insert into private.mobile_push_devices (session_id, recipient_id, token)
  values (active_session_id, account_id, device_token)
  on conflict (session_id) do update set token = excluded.token;
end
$$;
revoke all on function public.set_mobile_notification_token(text) from public, anon, authenticated;
grant execute on function public.set_mobile_notification_token(text) to authenticated;

create function private.enqueue_mobile_push()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into private.mobile_push_queue (notice_id, session_id)
  select new.id, device.session_id
  from private.mobile_push_devices device where device.recipient_id = new.recipient_id
  for key share of device skip locked;
  return new;
end
$$;
revoke all on function private.enqueue_mobile_push() from public, anon, authenticated;
create trigger enqueue_mobile_push after insert on public.app_notifications
for each row execute function private.enqueue_mobile_push();

create function public.claim_mobile_push_jobs(worker_token text)
returns table(job_id bigint, attempt integer, token text, notice_id bigint)
language plpgsql security definer set search_path = ''
as $$
begin
  if worker_token is null or not exists (
    select 1 from vault.decrypted_secrets
    where name = 'uth_mobile_push_worker_token' and decrypted_secret = worker_token
  ) then
    raise exception 'Invalid push worker token' using errcode = '42501';
  end if;
  delete from private.mobile_push_queue q where q.created_at < now() - interval '1 day'
    or (q.attempt >= 5 and q.available_at <= now());
  return query
  with ready as (
    select q.id from private.mobile_push_queue q
    where q.available_at <= now() and q.attempt < 5
    order by q.available_at, q.id limit 25 for update skip locked
  ), claimed as (
    update private.mobile_push_queue q
    set attempt = q.attempt + 1, available_at = now() + interval '2 minutes'
    from ready where q.id = ready.id
    returning q.id, q.attempt, q.session_id, q.notice_id
  )
  select c.id, c.attempt, d.token, c.notice_id from claimed c
  join private.mobile_push_devices d on d.session_id = c.session_id
  join auth.sessions s on s.id = c.session_id
    and (s.not_after is null or s.not_after > now())
  join public.app_notifications n on n.id = c.notice_id and not n.is_read;
end
$$;
revoke all on function public.claim_mobile_push_jobs(text) from public, anon, authenticated;
grant execute on function public.claim_mobile_push_jobs(text) to service_role;

create function public.finish_mobile_push_job(job_id bigint, job_attempt integer, invalid_token text default null)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  device_session uuid;
begin
  delete from private.mobile_push_queue where id = job_id and attempt = job_attempt
  returning session_id into device_session;
  if invalid_token is not null and device_session is not null then
    delete from private.mobile_push_devices where session_id = device_session and token = invalid_token;
  end if;
end
$$;
revoke all on function public.finish_mobile_push_job(bigint, integer, text) from public, anon, authenticated;
grant execute on function public.finish_mobile_push_job(bigint, integer, text) to service_role;
