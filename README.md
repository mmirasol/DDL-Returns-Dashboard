# DDL Returns

One list that Anton, Jerald and Alyza all use, replacing the weekly emailed
spreadsheet and the hand-maintained `Return to UNLEASHED.xlsx`. How each person
uses it: [RUNBOOK.md](RUNBOOK.md).

Same shape as the other DDL dashboards: a single `index.html` served by GitHub
Pages, talking to Supabase from the browser, so a data change needs no commit,
no rebuild and no redeploy.

## The flow

A **batch** is a set of locks inspected together. It is not tied to a week and
stays open until Anton says it is ready, which is how the source workbook
already worked (`4th BATCH (Oct 31 & Nov 13)`).

| Stage | Who | What they do | Batch status |
|---|---|---|---|
| 1 | **Anton** | Adds rows and fills every field: model, colour, qty, serial, order no, verdict, comment. Send is disabled until model, colour, qty and serial are filled on every row that is not scrap. | `draft` → `with_jerald` |
| 2 | **Jerald** | Sees only sent batches, scrap rows stripped out. Records the Unleashed stock adjustment number, which closes the batch. Emailed when a batch arrives. | `with_jerald` → `closed` |
| — | **Alyza** | Read-only search across every return, for support follow-ups. | none |

Anton can take a sent batch back until Jerald closes it. He can read closed
batches but not change them.

**Changed 17 Nov 2026**: Alyza's completing and endorsing step was removed at
Mark's request; Anton now does all the data entry and sends straight to Jerald.
`with_alyza` stays in the schema's check constraint, and any batch left in it is
treated as still with Anton.

### Jerald's email

`sql/notify_jerald.sql` adds a trigger on `returns_batch` that posts every status
change to the n8n workflow `DDL Returns → email Jerald when a batch is sent`
(`pqr5LM7SbDrOCBt8`) on samddl1973.app.n8n.cloud. The workflow emails Jerald only
when the new status is `with_jerald`, through the `Microsoft Outlook - mark`
credential. No Supabase key is stored in n8n for this.

## Running it

Out of the box the page runs as a **preview**: it loads the migrated history
from `data/history.json` and keeps edits in the browser's local storage. Good
for walking someone through it, useless as a shared tool.

To make it real:

1. Run `sql/schema.sql` in the Supabase SQL editor.
2. Run `sql/seed_legacy.sql`, which loads the history.
3. Put the project URL and publishable key into the two constants at the top of
   the `<script>` block in `index.html`.

### Note on access

`sql/schema.sql` turns RLS on and grants read and write to **signed-in users
only**. The other DDL dashboards are read-only, so an open publishable key costs
nothing there. This one is written to every day, and the key is visible in the
page source of a public repo, so anonymous write would mean anyone with the URL
could rewrite the returns log. Sign-in is the cheapest thing that prevents it.

## The migrated history

`data/history.json` and `sql/seed_legacy.sql` are generated from
`Return to UNLEASHED.xlsx`, sheet `FINAL`:

- **55 batches, 712 rows**, plus Anton's 28 October batch of 12
- 46 repeated header rows and the date separator rows dropped
- `GOOD TO RESELL` was free text in 93 spellings. It is normalised to
  `good` / `scrap` / `unsure`, and the original string is kept in
  `legacy_resell` so the normalisation can always be checked
- 17 distinct `SA-########` stock adjustment numbers lifted out of the status
  column onto the rows and batches they belong to

Nothing from the workbook is discarded: `legacy_resell`, `legacy_status` and
`legacy_agent` carry the original text.

## Known gaps

- **Bunnings.** Anton's list excludes Bunnings returns and nothing on record
  says where they go instead, so they enter this tool nowhere.
- `opened_on` could not be read from one of the 55 batch labels.
