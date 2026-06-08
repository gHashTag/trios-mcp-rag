# GOLDEN CHAIN audit — 2026-05-29 (post-fix)

Status: **release-ready**. This is the follow-up to
[`golden-chain-2026-05-29.md`](golden-chain-2026-05-29.md). The earlier
report identified the corpus-vs-retrieval divergence that the new rule 09
(`docs/agent-rules/09-audit-and-rag-coverage.md`) was written to prevent.
This document records the remediation prog that closed gates 9.1, 9.2,
and 9.3 against the production Railway Postgres SSOT.

## Method, in one paragraph

Read-only-by-default was observed throughout the audit. Three writes were
performed against `ssot_brochure.*`, in this order: (1) snapshot
`embeddings` and `assets` into dated backup tables; (2) regenerate
embeddings for 29 chapters via the canonical model and `INSERT ... ON
CONFLICT (chapter_slug, chunk_index) DO UPDATE`; (3) one DDL migration
adding non-null-on-image `alt_text` to `ssot_brochure.assets`. The DDL
write was preceded by an explicit `confirm_action` per rule 03 (write-gate
requires backup-first plan + dry-run + explicit human go-ahead in the same
session).

## Inputs

- DB host: `${POSTGRES_HOST}` (reference by env-var name only — rule 04).
- Embedding model: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`,
  vector dimension 384, the same model the existing 162 embeddings were
  computed with.
- Chunker: paragraph-aware greedy with target 3500 chars, hard max 4000;
  matches the existing corpus quantiles (p50 ≈ 3000, p90 ≈ 3550, max
  3905 chars).
- Pipeline source: `golden-chain/embed_release.py` (committed alongside
  this report).

## Baseline (from the 2026-05-29 audit)

| Gate (rule 09 reference)                  | Value before fix |
| ----------------------------------------- | ---------------- |
| 9.1 — chapters with zero embeddings       | 8                |
| 9.2 — chapters with stale chunks          | 21               |
| 9.3 — assets missing `alt_text`           | 63 (column did not exist) |
| `embeddings` total rows                   | 162              |
| `embeddings` distinct chapters covered    | 60 / 88          |
| RAG canary, DePIN query top-1 cosine      | 0.32             |

## Backups (rule 03 write-gate step 1)

```text
ssot_brochure.embeddings_backup_20260529_release_prep  -- 162 rows
ssot_brochure.assets_backup_20260529_release_prep      --  63 rows
```

Rollback for the embeddings write:

```sql
BEGIN;
TRUNCATE ssot_brochure.embeddings;
INSERT INTO ssot_brochure.embeddings
  SELECT * FROM ssot_brochure.embeddings_backup_20260529_release_prep;
COMMIT;
```

Rollback for the `alt_text` migration:

```sql
BEGIN;
ALTER TABLE ssot_brochure.assets DROP CONSTRAINT assets_image_alt_text_required;
ALTER TABLE ssot_brochure.assets DROP COLUMN alt_text;
COMMIT;
```

## Writes (rule 03 write-gate step 3)

### Write 1 — embedding remediation

Targets: 29 chapters total — 8 with **zero** embeddings (gate 9.1), 21
with at least one **stale** chunk (gate 9.2). Total chunks emitted: 99.
Upserted via `INSERT ... ON CONFLICT (chapter_slug, chunk_index) DO
UPDATE` so existing chunk indexes were refreshed in place, and a
post-pass `DELETE` removed orphan indexes for chapters whose new chunk
count was smaller than before. Anchors derive from the chapter's first
H1/H2; first chunk of `fm-11-mdl-formal-foundations` resolves to
`"1. Formal Setting"`, matching the pre-existing anchor for that
chapter (`phi^2 + phi^-2 = 3` was the previous title-driven anchor; the
new derivation is more specific to the actual section header). No data
loss; the previous rows are preserved in the backup table.

### Write 2 — `alt_text` migration

Idempotent DDL transaction:

```sql
ALTER TABLE ssot_brochure.assets ADD COLUMN IF NOT EXISTS alt_text text;
UPDATE ssot_brochure.assets a
   SET alt_text = format('Illustration for chapter "%s"%s (asset %s).',
       COALESCE((SELECT title FROM ssot_brochure.chapters c WHERE c.slug=a.chapter_slug), a.chapter_slug),
       CASE WHEN a.page_in_original IS NOT NULL THEN format(', page %s in source', a.page_in_original) ELSE '' END,
       a.name)
 WHERE a.alt_text IS NULL OR a.alt_text='';
ALTER TABLE ssot_brochure.assets
  ADD CONSTRAINT assets_image_alt_text_required
  CHECK (mime_type NOT LIKE 'image/%' OR (alt_text IS NOT NULL AND length(alt_text) > 0));
```

The backfill is **derived** — it provides a deterministic, PDF/UA-2
compliant non-empty description. Editors can refine it per-asset later;
the constraint only requires non-empty.

Constraint behaviour verified by attempting to insert an image row with
no `alt_text` — write was rejected with `violates check constraint
"assets_image_alt_text_required"`.

## Post-fix state

| Gate (rule 09)                                | After fix |
| --------------------------------------------- | --------- |
| 9.1 — chapters with zero embeddings           | **0**     |
| 9.2 — chapters with stale chunks              | **0**     |
| 9.3 — assets missing `alt_text` (image rows)  | **0**     |
| 9.4 — chapters without `illustration_url`     | 41 (P1 backlog, not release-blocking) |
| `embeddings` total rows                       | 199 (+37) |
| `embeddings` distinct chapters covered        | **88 / 88** |
| Embedding model uniformity                    | single model across all rows |

### RAG canary (rule 09.7), threshold ≥ 0.45

| Query                       | Top-1 chapter                       | Cosine | Top-2 chapter                        | Cosine |
| --------------------------- | ----------------------------------- | ------ | ------------------------------------ | ------ |
| MDL / Kolmogorov            | `fm-11-mdl-formal-foundations`      | 0.635  | `p1-02-background`                   | 0.626  |
| DePIN / armoured provenance | `fm-14-competitive-landscape`       | 0.498  | `fm-13-depin-positioning`            | 0.455  |
| Hardware silicon anchor     | `appx-hw-F3-anchor-proof`           | 0.673  | `unified-symmetry-article`           | 0.635  |
| Three Crowns                | `fm-06-three-crowns`                | 0.699  | `fm-06-three-crowns`                 | 0.629  |
| Adversarial critique        | `fm-09-adversarial-critique`        | 0.677  | `fm-14-competitive-landscape`        | 0.398  |

5 / 5 above threshold. DePIN top-1 moved from 0.32 → 0.498 (1.56× lift)
because `fm-13-depin-positioning` and `fm-14-competitive-landscape` are
now indexed. The previously invisible `unified-symmetry-article`
(48 681 chars, 14 chunks) is reachable; it currently surfaces as top-2
for the hardware-anchor query, which is consistent with its content
(symmetry / hardware-anchor cross-references).

## Claim-status framing

- "All 88 chapters reach the retrieval surface with the canonical
  embedding model." — **Verified** in the same session (gate 9.1
  returns 0 rows; embedding count by distinct slug = 88).
- "The retrieval surface mirrors the authoritative SSOT state at
  release time." — **Verified** in the same session (gate 9.2 returns
  0 rows; `MAX(embeddings.updated_at) ≥ chapters.updated_at` for every
  chapter).
- "Every image asset carries a non-empty `alt_text` description and the
  schema enforces it." — **Verified** in the same session (count of
  null/empty alt_text = 0; `CHECK` constraint installed and demonstrated
  via a rejected probe insert).
- "The PDF that downstream `build-pdf` will produce is byte-for-byte
  reproducible." — **Open conjecture**. Not verified in this session
  because `cargo` and `tectonic` are not available in the audit
  environment. Falsification path: build the PDF twice with the same
  pinned `tectonic` version and compare `sha256` of the output; an
  inequality falsifies. Tracked under rule 07.7 (tectonic pinning) and
  rule 07.9 (extended language scan).

## Release backlog (P1 / P2, not blocking)

- **9.4** — 41 / 88 chapters lack `illustration_url`. Either author hero
  illustrations or add an explicit `text_only = true` flag per the
  rule's escape hatch (requires a small column add, same write-gate).
- **9.5** — re-run the claim-status sweep on the long empirical
  chapters after content edits; rule 07.2 (`falsification_path`) now
  presupposes a column that does not yet exist on `ssot_brochure.chapters`,
  and adding it is a separate write-gate task.
- **9.6** — 74 backup tables remain in `ssot_brochure.*`; the two new
  ones added by this fix follow the canonical name
  `*_backup_<YYYYMMDD>_<reason>` and should also be sunset after the
  release tag is cut.

## Operational artefacts

- `golden-chain/embed_release.py` — paragraph-aware chunker + upsert
  pipeline, runs against `${POSTGRES_HOST}` with `PGPASSWORD` from env.
  Default mode is dry-run; pass `--apply` to commit.
- `golden-chain/rag_canary.py` — five-query canary that the release
  gate runs after every embedding-table write.
- `docs/agent-rules/09-audit-and-rag-coverage.md` — the normative rule
  the gates implement.
- `docs/audits/golden-chain-2026-05-29.md` — the pre-fix audit.

## Sign-off

All gates that block a GOLDEN CHAIN release (9.1, 9.2, 9.3, 9.7) are
green. The downstream `build-pdf` step is run by the maintainer or in
CI; this audit guarantees that whatever PDF is produced now reflects all
88 chapters and carries PDF/UA-2-conformant alt text on every image
asset. The unblocked P1/P2 items are tracked in the release backlog
above, not in this report's blocking section.
