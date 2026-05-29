# 09 — Audit & RAG Coverage Discipline

Status: **normative**. Derived from the GOLDEN CHAIN corpus audit on
2026-05-29 (`docs/audits/golden-chain-2026-05-29.md` in the
`trios-mcp-rag` repository). This rule formalises the audit gates that
the audit revealed were silently missing — chapters present in
`ssot_brochure.chapters` but invisible to RAG, stale embeddings drifting
out of sync, accessibility metadata declared in the canon but absent in
the actual schema, and uneven claim-status discipline across chapters.

The rule applies whenever an agent touches `ssot_brochure.*`, runs a
`build-pdf` cycle, rebuilds embeddings, ingests new chapters, or
publishes a derived artefact (PDF, brochure, README, article).

## Implementation

Reference implementation in this repo:
[`scripts/verify-ssot-integrity.sh`](../../scripts/verify-ssot-integrity.sh).

The script runs nine non-zero-exit invariants that map 1:1 to the
subsections below and to the waves 30–35 provenance commits:

  1. `ssot_brochure.chapters.sha256` column present and populated
     for every row (→ §9.6 SSOT hygiene).
  2. `ssot_brochure.chapters.word_count` column present and
     non-negative for every row.
  3. `illustration_url` foreign-key consistency against
     `ssot_brochure.assets` (→ §9.4 illustration coverage).
  4. `ssot_brochure.assets.byte_size` non-null, non-negative.
  5. `ssot_brochure.assets.sha256` non-null and 64-hex.
  6. `ssot_brochure.assets.chapter_slug` non-null FK back into
     `chapters.slug` (→ anti-orphan provenance).
  7. Every chapter row has `format = 'markdown'` (no silent format
     drift).
  8. `chapters.updated_at` trigger present and firing.
  9. `chapters.body_md` cross-reference fan-out (every internal
     anchor resolves; no dangling `#slug` links).

A wave that adds a new schema column or trigger MUST add the matching
invariant to the script in the same commit. The script is the only
sanctioned place where rule 09 leaves the documentation layer and
becomes executable, and CI runs it before any `build-pdf`. Embedding
coverage / freshness (§9.1 / §9.2) live in a separate Python check
and are not in scope of `verify-ssot-integrity.sh`.

---

## 9.1 — Embedding coverage gate (P0, hard)

**Invariant.** Every row in `ssot_brochure.chapters` with non-empty
`text` MUST have at least one row in `ssot_brochure.embeddings` whose
`chapter_slug` matches it, using the canonical SSOT embedding model
(currently `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`,
384-dim).

**Pre-build check (must run; build fails on non-zero).** Run before
`build-pdf` and before any RAG-backed claim is composed:

```sql
SELECT c.slug, char_length(c.text) AS body_chars
  FROM ssot_brochure.chapters c
  LEFT JOIN ssot_brochure.embeddings e ON e.chapter_slug = c.slug
 WHERE c.text IS NOT NULL
   AND char_length(c.text) > 200
   AND e.chapter_slug IS NULL
 ORDER BY body_chars DESC;
```

If this returns any rows, **stop**. Either re-run the embedding pipeline
for the missing slugs, or explicitly exclude those chapters from the
build manifest with a recorded reason. Do not silently ship a PDF where
N chapters are unreachable through retrieval.

**Why this is hard.** The 2026-05-29 audit found 8 chapters totalling
~18,800 words with zero embeddings, including high-impact slugs
(`unified-symmetry-article`, `gf-numeric-formats-history`,
`fm-13-depin-positioning`). The DePIN RAG canary scored only 0.32
similarity exactly because the relevant chapter was invisible to the
retriever. This is the failure mode the gate exists to prevent.

## 9.2 — Embedding freshness gate (P0)

**Invariant.** For every chapter, the most recent embedding row's
`updated_at` MUST be ≥ the chapter's `updated_at`. Stale chunks shipped
in a build silently retrieve outdated body text.

**Pre-build check.**

```sql
SELECT c.slug,
       c.updated_at        AS chapter_updated,
       MAX(e.updated_at)   AS last_embedding_updated,
       COUNT(e.*)          AS chunks
  FROM ssot_brochure.chapters c
  LEFT JOIN ssot_brochure.embeddings e ON e.chapter_slug = c.slug
 GROUP BY c.slug, c.updated_at
HAVING MAX(e.updated_at) IS NULL
    OR MAX(e.updated_at) < c.updated_at
 ORDER BY c.updated_at DESC;
```

If any rows return, refuse to claim "regenerated GOLDEN CHAIN". Re-embed
the listed slugs first. A build that ships with stale chunks must be
labelled **High-risk** in any release note.

The audit found 62 / 162 chunks stale (≈38 %). That is not "a build" —
that is a partial reflection of two corpus states pasted together.

## 9.3 — Accessibility metadata gate (P0)

**Invariant.** `ssot_brochure.assets` MUST expose an `alt_text` column
constrained `NOT NULL` on rows whose `kind` is `image`, `figure`, or
`illustration`. This makes PDF/UA-2 conformance enforceable at insert
time rather than at QA time.

**Schema migration required** (pending — propose, don't apply without an
explicit go-ahead per rule 03):

```sql
ALTER TABLE ssot_brochure.assets ADD COLUMN alt_text text;
-- Backfill before adding the constraint.
ALTER TABLE ssot_brochure.assets
  ADD CONSTRAINT assets_image_alt_text_required
  CHECK (kind NOT IN ('image','figure','illustration') OR alt_text IS NOT NULL);
```

Until that constraint exists, every `build-pdf` run MUST emit a
warning listing assets used in the build with empty / NULL `alt_text`,
and the QA checklist (rule 05) MUST gate the build on that warning being
zero.

The audit found the column missing entirely on a corpus with 63 assets.
Rule 07.6 (PDF/UA-2 / non-null `alt_text` from the literature-grounded
refinements) cannot be satisfied without this schema change.

## 9.4 — Illustration coverage gate (P1)

**Invariant.** Every chapter intended for the GOLDEN CHAIN PDF SHOULD
declare either a hero image (`illustration_url IS NOT NULL`) or be
explicitly marked text-only in the manifest. Half-coverage produces a
visually inconsistent PDF and violates `TRIOS_PHD_NO_IMAGE_TRAIN` from
the opposite direction (some sections get heroes, others don't, so the
ones that do cluster).

**Pre-build report.**

```sql
SELECT kind,
       COUNT(*)                                            AS chapters,
       COUNT(*) FILTER (WHERE illustration_url IS NOT NULL) AS with_hero,
       COUNT(*) FILTER (WHERE illustration_url IS NULL)     AS no_hero
  FROM ssot_brochure.chapters
 GROUP BY kind
 ORDER BY chapters DESC;
```

If `no_hero` is non-zero for any `kind` in the published TOC, either
add a hero or set an explicit `text_only = true` flag (introduce the
column if absent — same write-gate as 9.3).

Baseline at audit time: 41 / 88 chapters lacked `illustration_url`.

## 9.5 — Claim-status sweep gate (P1)

**Invariant.** Every chapter > 800 characters whose `kind` is in
{`paper1`,`paper2`,`paper3`,`hardware_addendum`,`appx_dna`,
`appx_catalog42`,`audit`} MUST contain at least one of the canonical
claim-status markers from rule 04 (`Verified`, `Empirical fit`,
`Open conjecture`, `High-risk`, `Retracted`) in the body text.

**Pre-build report.**

```sql
SELECT slug, kind, char_length(text) AS body_chars
  FROM ssot_brochure.chapters
 WHERE char_length(text) > 800
   AND kind IN ('paper1','paper2','paper3','hardware_addendum',
                'appx_dna','appx_catalog42','audit')
   AND text !~* '(Verified|Empirical fit|Open conjecture|High-risk|Retracted)'
 ORDER BY body_chars DESC;
```

The audit found 15+ long chapters with zero markers. Each missing
marker is a silent rule-04 violation, not a stylistic preference.

For each flagged chapter, either insert the appropriate label (with the
falsification path from rule 07.2 if `Open conjecture`) or move the
content into a clearly non-empirical section (`frontmatter`,
`backmatter`, narrative).

## 9.6 — SSOT hygiene (P2)

**Invariant.** Backup tables in `ssot_brochure.*` MUST follow a single
naming convention and carry a sunset date. Ad-hoc tables
(`*_before_*`, `chapters_w*_backup`, `*_old`) MUST be either renamed to
`backup_<iso-date>_<reason>` or dropped after their `retain_until` date
passes.

**Audit query.**

```sql
SELECT table_schema, table_name, pg_size_pretty(pg_total_relation_size(
         format('%I.%I', table_schema, table_name)::regclass)) AS size
  FROM information_schema.tables
 WHERE table_schema = 'ssot_brochure'
   AND (table_name ~* 'backup|_before_|_old|_w[0-9]+_')
 ORDER BY pg_total_relation_size(
         format('%I.%I', table_schema, table_name)::regclass) DESC;
```

The audit found 74 such tables consuming ~4.8 MB. This is not a
disk-space issue; it is a cognitive-load issue — agents writing queries
against `ssot_brochure.*` cannot tell at a glance which `chapters_*`
table is canonical.

## 9.7 — RAG canary smoke test (recommended)

Before any release-tagged GOLDEN CHAIN PDF, run a canary retrieval over
the canonical embedding model with at least three queries that exercise
distinct chapter clusters (e.g. one MDL/compression query, one
DePIN/economics query, one hardware/co-design query). Record cosine
similarity of the top-1 hit for each.

A top-1 similarity below 0.45 for a query whose target chapter exists
in the corpus is a coverage signal — investigate against rules 9.1 and
9.2 before signing off.

This is operational evidence that the RAG layer is actually working,
not just that the embeddings table is non-empty.

## 9.8 — Audit artefact requirement (P1)

For any work labelled "GOLDEN CHAIN audit", "SSOT audit", or "RAG audit"
in a commit message, PR title, or release note, the agent MUST write a
dated report to `docs/audits/golden-chain-<YYYY-MM-DD>.md` covering:

1. Counts and distribution of chapters by `kind`.
2. Embedding coverage (missing slugs from 9.1).
3. Embedding freshness (stale chunks from 9.2).
4. Assets coverage (alt_text status from 9.3, illustration coverage from
   9.4).
5. Claim-status sweep results from 9.5.
6. RAG canary results from 9.7.
7. A prioritised improvement list (P0/P1/P2).

The report is itself a derived artefact and MUST comply with rule 06
(English-only) and rule 04 (claim-status framing for any empirical
statement about the corpus).

The 2026-05-29 audit is the reference template.

---

## Where these gates live

The intended deployment is:

- `9.1`, `9.2`, `9.4`, `9.5` — pre-build checks called from the
  `build-pdf` tool itself, behind a `--audit-strict` flag that is
  **on by default for `book-mode`**.
- `9.3` — schema constraint (one-shot DDL after a backed-up dry-run).
- `9.6` — quarterly housekeeping, not blocking on a build.
- `9.7` — release-tag canary, scripted and stored under
  `tests/rag-canary/`.
- `9.8` — agent responsibility; not a tool gate.

Until those hooks exist in code, the agent runs the queries manually
and records the outcome in the PR description before merging anything
labelled "GOLDEN CHAIN release".
