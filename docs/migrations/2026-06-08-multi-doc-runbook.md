# Runbook: 2026-06-08 multi-doc SSOT migration

## Why

Until 2026-06-08 the Postgres SSOT `ssot_brochure.chapters` was implicitly
single-doc: every row belonged to the **GOLDEN CHAIN compendium** (v12,
69 rows). The pipeline (`build_pdf` / `build_book`) just selected all rows
and concatenated them.

The user is now shipping a second arXiv-bound artefact:

> **paper3-methodology** — _An 84-Format Numeric Catalog with Bit-Exact
> Conformance Vectors_ (9 sections, ~3800 words, arXiv cs.AR + cs.MS).

The wrong way to host it is a parallel `ssot_paper3.chapters` schema.
That fragments the second brain. The right way is one SSOT, one tool,
one pipeline, with a `doc` column scoping each row to a document.

## What changed

### Schema (additive, backwards-compatible)

- New column: `ssot_brochure.chapters.doc TEXT NOT NULL`
- New index: `ix_chapters_doc_order (doc, order_key)`
- Existing 69 rows tagged `doc='golden-chain-compendium'` via DEFAULT
- DEFAULT then dropped so future inserts MUST specify `doc`

### Rust pipeline

- `BuildConfig::doc: Option<String>` (default `Some("golden-chain-compendium")`)
- `load_from_postgres()` probes `information_schema.columns` for `doc`;
  if present and `cfg.doc` is set, query becomes
  `SELECT ... FROM ssot_brochure.chapters WHERE doc = $1 ORDER BY order_key`
- If `doc` column is absent (pre-migration DB) the query falls back to
  the legacy unfiltered form — no behaviour change for old deployments
- `count_chapters()` follows the same probe-and-fall-back pattern
- `BuildReport.doc: Option<String>` surfaces the active doc in the dry-run
  and final reports

### MCP

- `build_pdf` and `build_book` accept an optional `doc` argument
  (`"golden-chain-compendium"` | `"paper3-methodology"` | `null`)
- When `pdf_name` is not explicitly set, the filename is auto-picked
  from the active doc: `GOLDEN_CHAIN_compendium.pdf` / `paper3_methodology.pdf`

## Apply the migration

### Prerequisites

1. Railway → service `trios-mcp-rag` → Variables: `DATABASE_URL` is set
2. You have psql installed locally (or use Railway dashboard SQL console)
3. Most recent SSOT backup exists. If unsure, run the MCP tool
   `backup_ssot(confirm=true)` from the MCP client BEFORE step 1 below.

### Step 1 — apply schema migration

```bash
psql "$DATABASE_URL" -f docs/migrations/2026-06-08-multi-doc.sql
```

Expected output (key lines):

```
   step     |  n
------------+----
 rows_before| 69
 rows_tagged_compendium | 69
 rows_after | 69
 distinct_docs | golden-chain-compendium | 69
COMMIT
```

If `rows_before` != `rows_after` or `rows_tagged_compendium` < 69, the
transaction aborts. Re-investigate before retrying.

### Step 2 — insert paper3-methodology chapters

```bash
psql "$DATABASE_URL" -f docs/migrations/2026-06-08-paper3-inserts.sql
```

Expected output:

```
 paper3_rows | 9
COMMIT
```

The script has two preflight guards:

- Aborts if `doc` column is missing (Step 1 not applied)
- Aborts if `paper3-methodology` rows already exist (idempotent guard)

### Step 3 — verify via MCP

From an MCP client (or `cargo run`):

```jsonc
// dry-run, default doc = compendium
build_pdf({"dry_run": true})
// expected: chapter_count == 69, doc = "golden-chain-compendium"

// dry-run, paper3
build_pdf({"dry_run": true, "doc": "paper3-methodology"})
// expected: chapter_count == 9, doc = "paper3-methodology"

// legacy / no filter
build_pdf({"dry_run": true, "doc": null})
// expected: chapter_count == 78 (69 + 9)
```

### Step 4 — full build of paper3 (when ready)

```jsonc
build_pdf({
  "dry_run": false,
  "doc": "paper3-methodology",
  "book_mode": false
})
// produces: generated/out/paper3_methodology.pdf
```

## Rollback

### If Step 2 fails

```sql
BEGIN;
DELETE FROM ssot_brochure.chapters WHERE doc='paper3-methodology';
COMMIT;
```

### If Step 1 fails (rare — it is a single transaction)

```sql
BEGIN;
DROP INDEX IF EXISTS ix_chapters_doc_order;
ALTER TABLE ssot_brochure.chapters DROP COLUMN IF EXISTS doc;
COMMIT;
```

After full rollback the database is byte-identical to its pre-migration
state and the Rust pipeline falls back to legacy unfiltered queries.

## Provenance

| Artefact | SHA-256 |
| --- | --- |
| `2026-06-08-multi-doc.sql` | `f641ba99111998eb1b77ea31956796eee7faf24addf7b6c972f998c41fe72645` |
| `2026-06-08-paper3-inserts.sql` | `3cccf845d842eea7a51c8e7d333a600d69c6f061c4a0eade3a37b9ec4d796034` |
| `paper3-01-introduction.md` | `5cc8fe...` (see MANIFEST.json) |
| ... | (full per-chapter table in MANIFEST.json) |

Branch: `feat/multi-doc-ssot` of `gHashTag/trios-mcp-rag`.
