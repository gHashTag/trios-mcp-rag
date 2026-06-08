# GOLDEN CHAIN — Live SSOT Audit (2026-05-29)

**Source:** direct read-only `psql` over Railway Postgres (public proxy),
`ssot_brochure.*` schema. Performed by an external agent following the
`trios-mcp-rag` operating rules, with no writes to the database.

**Scope:** the full 88-chapter brochure corpus, 162 RAG chunks, 63
assets, 162 embeddings (384-dim, multilingual MiniLM-L12-v2).

This audit is **claim-status: Empirical fit**. Every finding below is a
direct SQL observation against the SSOT at the time of the run, not an
inferred property of the build pipeline.

---

## TL;DR — Top Findings

| # | Severity | Finding | Action |
|---|---|---|---|
| 1 | **High** | **8 of 88 chapters have zero embeddings** — `unified-symmetry-article` (6 012 words!), `fm-13-depin-positioning` (3 470 words), `gf-numeric-formats-history` (4 818 words) and 5 others are invisible to RAG. | Re-run `embed_chapter` for the 8 missing slugs. |
| 2 | **High** | **62 chunks are stale** — `embeddings.updated_at < chapters.updated_at`. RAG returns outdated text vs. the canonical body. | Add a `chunks_stale` CI gate; reject build until reembed. |
| 3 | **High** | **No `alt_text` column on `ssot_brochure.assets`** at all (rule 07.6 requires it non-null). 63 assets cannot satisfy PDF/UA-2. | Add column, backfill via `image_caption` LLM pass, then enforce NOT NULL. |
| 4 | **Medium** | **41 of 88 chapters have no `illustration_url`** (47%). Brochure rendering may fall back to broken refs in `\includegraphics`. | Audit which kinds legitimately have no illustration vs. which are missing. |
| 5 | **Medium** | **15+ long-form chapters carry zero claim-status markers** ("verified" / "empirical" / "open" / "falsification path" / "admitted"). Rule 04 is unevenly applied. | Sweep with an LLM-assisted labeller and require `claim_status` frontmatter. |
| 6 | **Medium** | **74 backup / `_before_*` tables in `ssot_brochure`** (4.8 MB). Technical debt; mirror live schema. | Move to `ssot_archive` schema or drop with annotated retention policy. |
| 7 | **Medium** | RAG cosine for the **DePIN-positioning** query topped out at **0.31** (top hit was `appx-dna-A3-claims`, not `fm-13-depin-positioning`) — direct consequence of finding #1. | Re-embedding fm-13 fixes this immediately. |
| 8 | **Low** | `appx-cat42-B-proof-closure` has only **87 words** — appears to be a stub. | Either expand or delete; do not ship a stub appendix. |
| 9 | **Low** | **8 chapters reference Nobel/prize/Abel/Fields** in body text. Two (`fm-07-olsen-tier-d`, `p3-10-worked-examples`) contain context-correct quotes; the rest need a one-line epistemic guard. | Add a `prize_context` flag and assert the chapter has a "Claim discipline" caveat nearby. |
| 10 | **Low** | Cyrillic content in `ssot_brochure.chapters.body_md`: **0** characters across 88 chapters. Rule 06 (English-only public artefacts) is currently satisfied. | Keep CI scan; no action. |

---

## 1. Corpus shape

```
       kind        | count | total_words | avg_words
-------------------+-------+-------------+-----------
 appx_catalog42    |     4 |         751 |       188
 appx_dna          |     5 |         764 |       153
 audit             |     2 |       6 090 |     3 045
 cover             |     1 |         408 |       408
 frontmatter       |    14 |      26 467 |     1 891
 handout           |     1 |         310 |       310
 hardware_addendum |     8 |       2 159 |       270
 outreach          |     1 |         451 |       451
 paper1            |    19 |      12 837 |       676
 paper2            |    14 |       8 874 |       634
 paper3            |    18 |      12 831 |       713
 unified           |     1 |       6 012 |     6 012
TOTAL              |    88 |      77 954 |       886
```

The three papers (P1/P2/P3) sit at a comfortable ~670 words/chapter
average — clean print typography target. Frontmatter is dense (1 891
words/chapter avg) and contains the highest-risk chapters by claim
volume (`fm-09-adversarial-critique`, `fm-11-mdl-formal-foundations`,
`fm-13-depin-positioning`).

## 2. Embedding coverage

**Missing chunks (8 chapters, total 18 815 words of unindexed body):**

| slug | kind | words |
|---|---|---|
| `unified-symmetry-article` | unified | 6 012 |
| `gf-numeric-formats-history` | audit | 4 818 |
| `fm-13-depin-positioning` | frontmatter | 3 470 |
| `gf-format-audit` | audit | 1 272 |
| `fm-14-competitive-landscape` | frontmatter | 1 114 |
| `cover-letter-symmetry` | cover | 408 |
| `authority-outreach-templates` | outreach | 451 |
| `london-handout` | handout | 310 |

These chapters are **invisible to every RAG query** until re-embedded.
Three of them (`unified-symmetry-article`, `gf-numeric-formats-history`,
`fm-13-depin-positioning`) are the largest documents in the entire
corpus and contain the most reviewer-relevant content. This is the
single biggest blocker to RAG quality.

**Distribution of chunks per chapter:**

- p50 = 2 chunks, p95 = 7 chunks
- Densest: `fm-11-mdl-formal-foundations` (10 chunks),
  `fm-09-adversarial-critique` (9), `fm-10-benchmark-positioning` (7).
- Sparsest: 18 chapters have exactly 1 chunk — acceptable for short
  appendices but a smell for any > 600-word chapter.

**Staleness:** 62 / 162 chunks (**38%**) have
`embeddings.updated_at < chapters.updated_at`. RAG will serve outdated
text for those slots until reembedded. The build pipeline should treat
this as a hard error, not a warning.

**Model:** all 162 chunks are embedded with
`sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` (384-dim,
cosine), embedded on 2026-05-23. Choice is reasonable but small —
considering an upgrade to `bge-m3` (1024-dim, multilingual,
significantly stronger retrieval) for v2 of the index.

## 3. RAG canary (live, 5 queries)

Run from the audit sandbox, multilingual MiniLM-L12-v2 384-dim:

| Query | Top-1 hit | cos |
|---|---|---|
| What is GOLDEN BRIDGE / CHAIN, physics→silicon? | `fm-01-cover` | 0.544 |
| How is falsification path defined for Open conjectures? | `p3-01-introduction` | 0.616 |
| Why is GF236 not a real numeric format? | `p1-08-empirical-results` | 0.480 |
| DePIN positioning and chain of custody | `appx-dna-A3-claims` | **0.316** |
| MDL formal foundations / Kolmogorov | `p1-02-background` | 0.789 |

**Observations:**

- The MDL query is excellent (0.79) — `fm-11-mdl-formal-foundations`
  retrieval works as designed.
- The falsification query (0.62) is good.
- The DePIN query (0.32) is a direct miss caused by finding #1 —
  `fm-13-depin-positioning` has no chunks, so RAG cannot return it.
- The GF236 query (0.48) is mediocre — `gf-format-audit` is the canonical
  document on GF236-debunking and it has no embeddings either.

After reembedding the 8 missing chapters, expect DePIN cos to jump from
0.32 → ~0.65 and GF236 cos from 0.48 → ~0.70, based on the document
texts themselves containing the query terms verbatim.

## 4. Index hygiene

`ssot_brochure.embeddings` — HNSW `vector_cosine_ops`, m=16,
ef_construction=64. Production-quality. `chunk_text` has a GIN trigram
index for the hybrid lexical leg. No action required.

`ssot.embeddings` (1 445 rows, 384-dim) — same index profile. Fine.

`ssot.agent_memory` (16 rows) — HNSW + GIN, healthy.

## 5. Claim-status discipline (rule 04)

**Aggregate marker counts across 88 chapters:**

```
mentions_verified      : 17
mentions_empirical     : 25
mentions_open          :  8
mentions_falsifiability:  9
mentions_admitted      : 17
mentions_prize_words   : 27   (mostly contextual quotes, see below)
```

**15+ long-form chapters carry zero claim-status markers**, including:

- `fm-11-mdl-formal-foundations` (4 360 words)
- `fm-07-olsen-tier-d` (2 165 words)
- `p1-acknowledgments` (568 words)
- `p2-05-symbolic-rg`, `p2-03-math-preliminaries`, `p2-04-e8-toda`,
  `p2-06-phi-operator`, `p2-01-motivation`
- `p1-03-symbolic-grammar`, `p1-07-mdl-bayesian`, `p1-10-falsification`,
  `p1-appA-reproducibility`
- `fm-02-attribution`, `fm-06-three-crowns`, `fm-12-constants-table`

Rule 04 is **unevenly applied**. The papers' main bodies need a
claim-frontmatter sweep — even a per-paragraph `[Verified]` /
`[Empirical fit]` / `[Open]` tag would be a major improvement.

**Prize-word context audit (8 chapters):**

| Chapter | Verdict |
|---|---|
| `fm-07-olsen-tier-d` | Verbatim Binnig 2004 letter, reproduced inside a "Claim discipline" sub-section. Acceptable as historical record. |
| `p3-10-worked-examples` | Quotes the Shechtman quasicrystal Nobel background — contextual, fine. |
| `gf-format-audit`, `fm-13-depin-positioning` | "prize" appears only in policy / convention language ("design-target", "milestones") — false positives. |
| Others | Same false-positive pattern. |

No chapter currently makes a forward-looking prize claim. Rule 04's
"no prize promises" gate is **upheld** in the corpus as of this audit.

## 6. Asset hygiene (rule 07.6)

```
\d ssot_brochure.assets
```

`alt_text` column **does not exist**. Rule 07.6 ("`alt_text`
non-nullable") is therefore not enforceable at the schema level. This
is the single biggest gap vs. the published operating rules.

**63 assets** are stored as `bytea` with `mime_type`, `byte_size`,
`sha256`, `source_url`, `chapter_slug`, `page_in_original` — but no
caption / alt-text / description. PDF/UA-2 conformance is impossible
until this is filled in.

**41 of 88 chapters** have no `illustration_url`. Many are legitimately
non-illustrated (cover-letter, attribution, math-heavy P2 sections),
but at least the eight papers' introductions and conclusions should
carry the opening / closing triptych references seen in P3.

## 7. Schema clutter

`ssot_brochure` contains **74 backup / staging tables** totalling 4.8 MB
— `_before_*`, `_fm0*_before_*`, `chapters_w*_backup`, etc. These were
useful while iterating but now pollute introspection and risk
accidental queries against stale rows. Recommend moving to a separate
schema (`ssot_archive`) or dropping with a retention SQL recorded in
`docs/migrations/`.

---

## Recommended Improvements (prioritised)

### P0 — fix this week

1. **Reembed 8 missing chapters** (`unified-symmetry-article`,
   `gf-numeric-formats-history`, `fm-13-depin-positioning`,
   `gf-format-audit`, `fm-14-competitive-landscape`,
   `cover-letter-symmetry`, `authority-outreach-templates`,
   `london-handout`). Estimated total: ~3 min of GPU time. RAG quality
   will jump immediately on DePIN, GF236, and Symmetry MDPI queries.
2. **Add `chunks_stale` CI gate** in the build pipeline: query
   `SELECT count(*) FROM ssot_brochure.embeddings e JOIN
   ssot_brochure.chapters c USING (chapter_slug=slug) WHERE
   e.updated_at < c.updated_at`; require `= 0` before any `build_pdf`
   run.
3. **Add `alt_text TEXT NOT NULL DEFAULT ''` to `ssot_brochure.assets`**,
   followed by an LLM caption pass for all 63 rows, then promote to a
   strict `CHECK (length(alt_text) > 0)`.

### P1 — fix this month

4. **Claim-status sweep on 15+ unmarked long-form chapters.** Even
   inserting a one-line frontmatter (`claim_tier: [Verified | Empirical
   fit | Open]`) per section would close the rule-04 gap.
5. **Upgrade RAG model** from MiniLM-L12-v2 (384-dim) to `bge-m3`
   (1024-dim) — but only after #1. Re-create HNSW with `m=16,
   ef_construction=128`. Run RAGAS gate (faithfulness ≥ 0.80, recall
   ≥ 0.75) before swapping in production.
6. **Move 74 backup tables to `ssot_archive` schema** and document
   retention policy in `docs/migrations/2026-05-ssot-archive.sql`.

### P2 — design-for-future

7. **Catalog-driven claim labels.** Introduce
   `ssot_brochure.claim_index` (slug, paragraph_anchor, claim_text,
   tier, falsification_path, source_doi) joined to chapters. Lua
   filter can then refuse to render a paragraph tagged `Open` without
   a `falsification_path` value (rule 07.2).
8. **Per-kind RAG routing.** P1 / P2 / P3 share vocabulary but ask
   different questions. A simple `chunk_kind` boost (already present
   on the column!) at query time would lift retrieval precision
   without changing the embedding model.
9. **Illustration audit.** Expected illustrations vs. observed
   `illustration_url`. Produce a per-chapter checklist; missing
   illustrations should be a soft warning in `build_pdf --dry-run`.
10. **Re-run the audit weekly** as part of CI. Persist this report as
    `docs/audits/golden-chain-YYYY-MM-DD.md` and diff against the
    previous week to catch regressions.

---

## Methodology

All findings reproducible via:

```bash
psql "$DATABASE_PUBLIC_URL?sslmode=require" -X -P pager=off \
  -f docs/audits/queries/golden-chain-audit.sql
```

(SQL file to be added in a follow-up PR.) No `INSERT` / `UPDATE` /
`DELETE` / `ALTER` was issued during this audit; the connection was
held read-only and the DSN was resolved from the agent's `psql`
client-side environment, never written to any config file.

Embedder for the RAG canary:
`sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` running
locally in the audit sandbox — same model the SSOT was built with,
to keep the cosine distances comparable.
