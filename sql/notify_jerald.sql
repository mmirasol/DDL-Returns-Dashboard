-- DDL Returns: email Jerald when Anton sends a batch.
-- Run once in the Supabase SQL editor, Other-Dashboard (tfpgywqmwnjesesfcmcg).
--
-- When a batch's status changes, this posts the old and new row to the n8n
-- workflow "DDL Returns → email Jerald when a batch is sent" (pqr5LM7SbDrOCBt8).
-- n8n emails Jerald only when the new status is with_jerald. No Supabase key
-- lives in n8n for this. Additive: one function, one trigger, nothing else touched.

create extension if not exists pg_net;

create or replace function returns_notify_jerald() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(
    url     := 'https://samddl1973.app.n8n.cloud/webhook/65bff1b9-1820-47b1-b03d-cea1436b0f85',
    body    := jsonb_build_object('type', 'UPDATE', 'table', 'returns_batch',
                                  'record', to_jsonb(new), 'old_record', to_jsonb(old)),
    headers := '{"Content-Type": "application/json"}'::jsonb
  );
  return new;
end $$;

drop trigger if exists returns_notify_jerald on returns_batch;
create trigger returns_notify_jerald
  after update of status on returns_batch
  for each row
  when (new.status is distinct from old.status)
  execute function returns_notify_jerald();
