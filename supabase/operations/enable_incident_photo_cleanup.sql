-- Run on the target Supabase project after deploying and verifying the worker.
-- Set uth_incident_cleanup_url and uth_incident_cleanup_gateway_jwt in Vault first.
create extension if not exists pg_cron;
create extension if not exists pg_net;

do $setup$
begin
  if not exists (
    select from vault.decrypted_secrets
    where name = 'uth_incident_cleanup_url'
      and decrypted_secret ~ '^https://[a-z0-9]+[.]supabase[.]co/functions/v1/clean-expired-incident-photos$'
  ) or not exists (
    select from vault.decrypted_secrets
    where name = 'uth_incident_cleanup_gateway_jwt' and decrypted_secret like 'eyJ%.%.%'
  ) then
    raise exception 'Missing cleanup endpoint or gateway JWT in Vault';
  end if;
  if not exists (select from vault.secrets where name = 'uth_incident_cleanup_token') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'uth_incident_cleanup_token'
    );
  end if;
end
$setup$;

select cron.schedule('uth-clean-expired-incident-photos', '15 20 * * *', $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets
      where name = 'uth_incident_cleanup_url'),
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets
        where name = 'uth_incident_cleanup_gateway_jwt'),
      'x-cleanup-token', (select decrypted_secret from vault.decrypted_secrets
        where name = 'uth_incident_cleanup_token'),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  );
$job$);

drop policy if exists incident_images_delete_expired_draft on storage.objects;
