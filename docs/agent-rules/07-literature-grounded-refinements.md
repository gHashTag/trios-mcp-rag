# Rule 07 — Literature-Grounded Refinements

These refinements were added on 2026-05-29 after a four-track literature
review (see [`docs/literature/`](../literature/)). They **extend, not
replace**, rules 00–06. Each refinement is normative: a build that
violates any of them fails QA in the same way as a `pdfinfo` / `qpdf`
failure.

The full citations supporting each item live in
[`docs/literature/05-cross-cutting.md`](../literature/05-cross-cutting.md);
do not re-derive the reasoning here — read the canon when in doubt.

## 1. RAGAS CI gate

A versioned 20-question probe set lives in the repo and is run as part
of the CI pipeline. Failing thresholds block the build:

- `faithfulness ≥ 0.80`
- `context_recall ≥ 0.75`

See Track 2 in [`docs/literature/02-rag-over-ssot.md`](../literature/02-rag-over-ssot.md).

## 2. `falsification_path` is mandatory for every Open conjecture

The Popperian requirement converges with the agentic-validation
literature: every claim labelled **Open conjecture** in
`ssot_brochure.chapters` (or its claim subtable) must populate a
non-null `falsification_path` column stating a conceivable disconfirming
observation. A build containing Open-conjecture claims without
falsification paths must fail the QA checklist in rule 05.

See Track 3 in [`docs/literature/03-claim-status-calibration.md`](../literature/03-claim-status-calibration.md).

## 3. Adjacent-literature anchoring

Track 1 of the canon (search performed 2026-05-29 across arXiv, Google
Scholar, Semantic Scholar, and OpenReview) returned **zero peer-reviewed
publications** under "TRIOS", "S³AI", "GOLDEN BRIDGE", or the
`gHashTag` author handle. Consequently:

- Every new chapter that makes an algorithmic or empirical claim MUST
  cite at least one external DOI from a recognised venue.
- Chapters without external citations are capped at **Open conjecture**
  for all their algorithmic claims, regardless of narrative framing.

When new TRIOS-authored peer-reviewed work appears, update
[`docs/literature/01-trios-s3ai-adjacent.md`](../literature/01-trios-s3ai-adjacent.md)
and relax this rule in the same PR.

## 4. Index hygiene pre-build

The pre-build hook MUST verify that the following indexes exist and
are not stale:

- `pgvector` HNSW index on the chapter-embedding column
- `tsvector` GIN index for full-text retrieval

If either is missing or stale, abort the build and report. Do not
silently degrade retrieval quality. The read-only default of rule 03
remains in force — this check is read-only.

See Track 2 in [`docs/literature/02-rag-over-ssot.md`](../literature/02-rag-over-ssot.md).

## 5. Epistemic-label propagation

Claim-status labels (Verified / Empirical fit / Open conjecture /
High-risk / Retracted) stored in Postgres must be emitted **verbatim**
into every derived artefact (PDF, README, brochure). The Lua filter
must not drop or suppress status markers during Markdown → LaTeX
conversion. Downstream automated QA (RAGAS, FActScore) depends on
labels surviving the pipeline.

## 6. `alt_text` is a first-class image-manifest field

Make `alt_text` non-nullable in the image manifest schema (see
[`docs/rag/IMAGE_MANIFEST_SCHEMA.md`](../rag/IMAGE_MANIFEST_SCHEMA.md)).
This is both a PDF/UA-2 accessibility requirement and the data-layer
enforcement of `TRIOS_PHD_NO_IMAGE_TRAIN` (rule 02 + `trios-phd-canon`).

## 7. No-image-train via penalty, not `\clearpage`

Enforce the keep-together rule for *section heading + hero/context
block + first paragraph(s)* using TeX penalties rather than hard page
breaks:

- `\widowpenalty=9999`
- `\clubpenalty=9999`
- `\needspace{}` guards on chapter openers
- `fig-pos: 'ht'` in YAML (not hard-coded `[H]`)

Hard `\clearpage` before every section is explicitly **prohibited** —
it produces short, title-only pages and excessive whitespace in
book-mode output, a known regression. See Track 4 in
[`docs/literature/04-reproducible-pdf-pipeline.md`](../literature/04-reproducible-pdf-pipeline.md).

## 8. Tectonic version pinning + reproducible-build hash

- Pin the tectonic version in `Cargo.toml` and the CI environment.
- Treat a tectonic upgrade as a pipeline change requiring full QA
  re-run, not a routine dependency bump.
- Neutralise the `CreationDate` non-determinism in the LaTeX preamble.
- Add an `sha256` of the output PDF to the build log; verify it
  matches the previous accepted build for identical SSOT content.
  Divergence is a build-system regression.

## 9. Extended language scan

The language scan in [`05-brochure-qa-checklist.md`](05-brochure-qa-checklist.md)
is extended to flag two new cases:

- Non-English claim-status markers appearing in public artefacts (an
  English-only policy breach — see rule 06).
- Internal inconsistency: a claim labelled **Open conjecture** whose
  body uses strong-assertion language ("proves", "demonstrates
  conclusively", "establishes"). Either re-label or re-word; a build
  may not ship the contradiction.

---

*Canon compiled 2026-05-29. When relaxing or strengthening any rule
here, also update the matching synthesis in
[`docs/literature/`](../literature/) and the canon's
"Recommendations" subsections to keep evidence and rule in sync.*
