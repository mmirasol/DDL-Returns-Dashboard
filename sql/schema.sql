-- DDL Returns: schema
-- Run this once in the Supabase SQL editor, then sql/seed_legacy.sql.
--
-- Two tables. A batch is a set of locks Anton inspected together; it is NOT tied
-- to a week and stays open until he says it is ready. A row is one lock.
--
-- Columns are grouped by who fills them:
--   Anton  lock_text, order_no, serial, verdict, notes
--   Alyza  model, colour, qty, customer, comment
--   Jerald sa_number
--
-- legacy_* holds the original free text from Return to UNLEASHED.xlsx so the
-- normalised verdict can always be checked against what was actually written.

create table if not exists returns_batch (
  id           bigserial primary key,
  ref          text unique,
  label        text not null,
  opened_on    date,
  status       text not null default 'draft'
               check (status in ('draft', 'with_alyza', 'with_jerald', 'closed')),
  sa_number    text,
  source       text not null default 'app' check (source in ('app', 'legacy')),
  legacy_block text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table if not exists returns_row (
  id            bigserial primary key,
  batch_id      bigint not null references returns_batch(id) on delete cascade,

  lock_text     text,
  order_no      text,
  serial        text,
  verdict       text not null default 'good' check (verdict in ('good', 'scrap', 'unsure')),
  notes         text,

  model         text,
  colour        text,
  qty           text,
  customer      text,
  comment       text,

  sa_number     text,

  legacy_resell text,
  legacy_status text,
  legacy_agent  text,

  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists returns_row_batch_idx  on returns_row (batch_id);
create index if not exists returns_row_serial_idx on returns_row (lower(serial));
create index if not exists returns_batch_status_idx on returns_batch (status);

-- keep updated_at honest
create or replace function returns_touch() returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists returns_batch_touch on returns_batch;
create trigger returns_batch_touch before update on returns_batch
  for each row execute function returns_touch();

drop trigger if exists returns_row_touch on returns_row;
create trigger returns_row_touch before update on returns_row
  for each row execute function returns_touch();

-- Row level security.
--
-- The page is served from GitHub Pages with a publishable key in the source, the
-- same as the other DDL dashboards. Those are read only; this one is not, so the
-- policies below are the difference between a tool three people use and a table
-- anyone with the URL can rewrite. They assume Supabase Auth: a signed-in user
-- can read everything and write, anonymous visitors can do neither.
--
-- If you would rather run it open for now, replace `authenticated` with `anon`
-- in the four policies below and understand what that means.

alter table returns_batch enable row level security;
alter table returns_row   enable row level security;

drop policy if exists returns_batch_read  on returns_batch;
drop policy if exists returns_batch_write on returns_batch;
drop policy if exists returns_row_read    on returns_row;
drop policy if exists returns_row_write   on returns_row;

create policy returns_batch_read  on returns_batch for select to authenticated using (true);
create policy returns_batch_write on returns_batch for all    to authenticated using (true) with check (true);
create policy returns_row_read    on returns_row   for select to authenticated using (true);
create policy returns_row_write   on returns_row   for all    to authenticated using (true) with check (true);
