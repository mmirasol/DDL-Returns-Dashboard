# DDL Returns

One list that Anton, Alyza and Jerald all use, replacing the weekly emailed
spreadsheet and the hand-maintained `Return to UNLEASHED.xlsx`.

Same shape as the other DDL dashboards: a single `index.html` served by GitHub
Pages, talking to Supabase from the browser, so a data change needs no commit,
no rebuild and no redeploy.

## The flow

A **batch** is a set of locks inspected together. It is not tied to a week and
stays open until Anton says it is ready, which is how the source workbook
already worked (`4th BATCH (Oct 31 & Nov 13)`).

| Stage | Who | What they do | Batch status |
|---|---|---|---|
| 1 | **Anton** | Adds, edits and deletes rows in the four fields he fills today. Sets the batch ready when it is inspected. | `draft` → `with_alyza` |
| 2 | **Alyza** | Sees only batches marked for her. Fills model, colour, quantity and customer. Endorse is disabled until nothing is missing. | `with_alyza` → `with_jerald` |
| 3 | **Jerald** | Sees only endorsed batches, scrap rows stripped out. Records the Unleashed stock adjustment number, which closes the batch. | `with_jerald` → `closed` |

Anton can reopen a batch he has sent. He can read closed batches but not change
them.

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
