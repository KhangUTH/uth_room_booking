-- Store the deployed send-mobile-push URL in Vault as uth_mobile_push_url.
-- Configure FCM_SERVICE_ACCOUNT_JSON as an Edge Function secret.
create extension if not exists pg_cron;
create extension if not exists pg_net;

do $setup$
begin
  if not exists (
    select 1 from vault.decrypted_secrets
    where name = 'uth_mobile_push_url'
      and decrypted_secret ~ '^https://[a-z0-9]+[.]supabase[.]co/functions/v1/send-mobile-push$'
  ) then
    raise exception 'Missing mobile push endpoint in Vault';
  end if;
  if not exists (select 1 from vault.secrets where name = 'uth_mobile_push_worker_token') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'uth_mobile_push_worker_token'
    );
  end if;
end
$setup$;

select cron.schedule('uth-send-mobile-push', '15 seconds', $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'uth_mobile_push_url'),
    headers := jsonb_build_object(
      'x-push-worker-token', (select decrypted_secret from vault.decrypted_secrets
        where name = 'uth_mobile_push_worker_token'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  )
  where exists (select 1 from private.mobile_push_queue where available_at <= now());
$job$);
