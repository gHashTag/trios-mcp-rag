# Build Audit — 2026-06-08 — Multi-Doc SSOT + paper3-methodology

## Summary

- **Migration:** add `doc` column to `ssot_brochure.chapters`, index by
  `(doc, order_key)`, tag existing 69 rows as `golden-chain-compendium`.
- **Inserts:** 9 new rows for `paper3-methodology` (the 84-format catalog
  paper, ~3800 words).
- **Pipeline:** `BuildConfig::doc` field, probe-and-filter SQL with
  graceful fallback for pre-migration databases.
- **Tests:** 14 (baseline) + 3 (new) = 17 passing, zero failing.
- **Branch:** `feat/multi-doc-ssot` on `gHashTag/trios-mcp-rag`.

## Chapter manifest (paper3-methodology)

| order_key | slug | words | badge | SHA-256 (head) |
| --- | --- | --- | --- | --- |
| 200_010 | paper3-01-introduction                  | ~370 | Verified         | (see MANIFEST.json) |
| 200_020 | paper3-02-background                    | ~430 | Verified         | |
| 200_030 | paper3-03-catalog-design                | ~610 | Verified         | |
| 200_040 | paper3-04-conformance-methodology       | ~460 | Verified         | |
| 200_050 | paper3-05-six-packs                     | ~890 | Empirical fit    | |
| 200_060 | paper3-06-p3109-crosswalk               | ~410 | Open conjecture  | |
| 200_070 | paper3-07-discussion-interpretation-gap | ~290 | Empirical fit    | |
| 200_080 | paper3-08-reproducibility-provenance    | ~350 | Verified         | |
| 200_090 | paper3-09-future-work                   | ~260 | Open conjecture  | |

`order_key = PAPER3_KIND_RANK * 1000 + N * 10`, where `PAPER3_KIND_RANK = 200`.
This is a fresh band, so order_key never collides with the compendium
order space — though `doc` is the real isolator.

## Hard-rule scan (paper3 chapters only)

Ran ASCII + banned-vocabulary scan on all 9 chapters:

```
non_ascii_chars: 0
em-dash / en-dash: 0
banned hits (breakthrough/revolution/world-first/industry-leading/
             first-ever/prize/nobel/DARPA/SBIR/CLARA/sponsor/grant/contract): 0
hype hits (proves): 0
```

## Compatibility

The migration is backwards-compatible at three levels:

1. **Database:** old build of `trios-mcp-rag` on the migrated DB still
   works — `SELECT ... FROM ssot_brochure.chapters ORDER BY order_key`
   returns all 78 rows in the right order. (The legacy build does not
   filter by doc, so it would render compendium + paper3 in one PDF, but
   that is by design — the legacy build is no longer the recommended
   path post-migration.)
2. **Pipeline:** new build on a non-migrated DB still works — the
   `information_schema` probe returns `has_doc = false` and the SQL
   falls back to the legacy unfiltered query.
3. **MCP:** existing MCP clients that omit `doc` get the compendium by
   default (the new default value of `BuildConfig::doc` is
   `golden-chain-compendium`).

## Five-layer audit trail (mirrors trinity-s3ai discipline)

1. **Reproducibility capsule:** `docs/papers/paper3-methodology/`
   contains every chapter as a frozen `.md` plus `MANIFEST.json` with
   per-chapter SHA-256.
2. **SQL provenance:** `docs/migrations/2026-06-08-multi-doc.sql` +
   `docs/migrations/2026-06-08-paper3-inserts.sql`, both committed.
3. **Pipeline diff:** `src/pipeline.rs` and `src/main.rs` in this branch
   show the exact code path that filters by `doc`.
4. **Unit tests:** `build_config_default_has_golden_chain_doc`,
   `build_config_doc_can_be_disabled`,
   `build_config_doc_paper3_round_trip`.
5. **Skill update:** `render-pipeline-mcp` and `scientific-works-canon`
   skills updated in the same sprint to reflect multi-doc SSOT.

## Open items (not blockers)

- **Pandoc template:** the existing `templates/chapter.template.tex` is
  tuned for the book-mode compendium (with TOC, parts, dividers). For
  paper3 we will likely use `book_mode=false` so the output is a single
  article-style PDF. If that is not enough we can ship a second template
  later; for now, `book_mode=false` is acceptable.
- **References:** paper3 uses inline `[citekey]` markers (placeholder
  Markdown style after the LaTeX-to-Markdown conversion). The
  paper-level bibliography lives in the original `paper/main.tex` and
  can be re-attached as a final chapter (`paper3-99-references`) if
  needed; or we accept that the SSOT-driven Markdown build is a
  pre-arXiv working PDF and we still ship the original `main.tex` to
  arXiv. This is a choice; the SSOT-driven build is for continuous
  agent regeneration, the LaTeX original is for camera-ready.

## Honest non-result

This migration does NOT produce a new PDF on its own. It produces:

- a clean two-doc SSOT;
- a tool (`build_pdf` with `doc` arg) that anyone (agent or human) can
  invoke to rebuild either document deterministically;
- a frozen audit anchor for paper3 chapters so future re-builds can
  diff against the SHA-256s in `MANIFEST.json`.

The PDF itself is a one-command call away from any environment that has
`DATABASE_URL` + pandoc + tectonic + this branch.
