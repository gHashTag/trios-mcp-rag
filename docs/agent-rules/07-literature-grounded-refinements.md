# Rule 07 — Literature-Grounded Refinements

These refinements were added on 2026-05-29 after a four-track literature
review (see [`docs/literature/`](../literature/)). They **extend, not
replace**, rules 00–06.

Each refinement carries an explicit **Status** line (added in v14 audit,
2026-05-29) so agents do not confuse aspirational gates with active
ones:

- **active** — the refinement is enforced today (template / Lua filter /
  build pipeline / pre-publish checklist already implements it). A
  build violating an `active` refinement fails QA the same way as a
  `pdfinfo` / `qpdf` failure.
- **planned** — the refinement depends on infrastructure not yet in
  the repo (CI workflow, schema column, materialised manifest, version
  pin). It is normative in *intent* but not gating builds today.
  Tracked in [`docs/literature/05-cross-cutting.md`](../literature/05-cross-cutting.md)
  with matching `deferred` tag.

The full citations supporting each item live in
[`docs/literature/05-cross-cutting.md`](../literature/05-cross-cutting.md);
do not re-derive the reasoning here — read the canon when in doubt.

## 1. RAGAS CI gate

**Status: planned** — no `.github/workflows/` RAGAS job exists today.
This section is normative once CI is wired; until then the equivalent
manual gate is `references/PDF_QA_CHECKLIST.md`.

A versioned 20-question probe set lives in the repo and is run as part
of the CI pipeline. Failing thresholds block the build:

- `faithfulness ≥ 0.80`
- `context_recall ≥ 0.75`

See Track 2 in [`docs/literature/02-rag-over-ssot.md`](../literature/02-rag-over-ssot.md)
and the `deferred` entry in [`docs/literature/05-cross-cutting.md`](../literature/05-cross-cutting.md).

## 2. `falsification_path` is mandatory for every Open conjecture

**Status: partially active** — the Markdown-paragraph form is **active**
and gating today: every **Open conjecture** claim body in
`ssot_brochure.chapters.body_md` must contain a labelled
`**Falsification path:**` paragraph, and the QA checklist enforces it.
The **schema-level** form (a dedicated `falsification_path` column with
a `NOT NULL` constraint conditioned on `claim_status = 'Open conjecture'`)
is **planned** — the current schema (slug, kind, order_key, title,
body_md, illustration_url) has neither column. Tracked under
`deferred` in cross-cutting.

The Popperian requirement converges with the agentic-validation
literature: every claim labelled **Open conjecture** in
`ssot_brochure.chapters` (or its claim subtable) must populate a
non-null `falsification_path` column stating a conceivable disconfirming
observation. Until the schema migration lands, the same invariant is
enforced via the Markdown-paragraph form. A build containing
Open-conjecture claims without falsification paths must fail the QA
checklist in rule 05.

See Track 3 in [`docs/literature/03-claim-status-calibration.md`](../literature/03-claim-status-calibration.md).

## 3. Adjacent-literature anchoring

**Status: active** — enforced by rule 04 + `trios-phd-canon.md`.

Track 1 of the canon (search performed 2026-05-29 across arXiv, Google
Scholar, Semantic Scholar, and OpenReview, re-verified post-v13)
returned **zero peer-reviewed publications** under "TRIOS", "S³AI",
"GOLDEN BRIDGE", or the `gHashTag` author handle. Consequently:

- Every new chapter that makes an algorithmic or empirical claim MUST
  cite at least one external DOI from a recognised venue.
- Chapters without external citations are capped at **Open conjecture**
  for all their algorithmic claims, regardless of narrative framing.

When new TRIOS-authored peer-reviewed work appears, update
[`docs/literature/01-trios-s3ai-adjacent.md`](../literature/01-trios-s3ai-adjacent.md)
and relax this rule in the same PR.

## 4. Index hygiene pre-build

**Status: planned** — no pre-build hook exists today; the embedding
table itself does not exist yet in the local mirror (rule 09 §9.1
specifies the missing `ssot_brochure.embeddings` table). Enforce
manually via SQL probe until the hook is implemented; tracked under
`deferred` in cross-cutting ("index-presence check").

The pre-build hook MUST verify that the following indexes exist and
are not stale:

- `pgvector` HNSW index on the chapter-embedding column
- `tsvector` GIN index for full-text retrieval

If either is missing or stale, abort the build and report. Do not
silently degrade retrieval quality. The read-only default of rule 03
remains in force — this check is read-only.

See Track 2 in [`docs/literature/02-rag-over-ssot.md`](../literature/02-rag-over-ssot.md).

## 5. Epistemic-label propagation

**Status: active** — enforced by Lua filter + rules 01 + 04.

Claim-status labels (Verified / Empirical fit / Open conjecture /
High-risk / Retracted) stored in Postgres must be emitted **verbatim**
into every derived artefact (PDF, README, brochure). The Lua filter
must not drop or suppress status markers during Markdown → LaTeX
conversion. Downstream automated QA (RAGAS, FActScore) depends on
labels surviving the pipeline.

## 6. `alt_text` is a first-class image-manifest field

**Status: planned** — the manifest schema is documented in
`IMAGE_MANIFEST_SCHEMA.md`, but no live JSON manifest is materialised
in the repo and no VeraPDF gate is wired. Heroes are picked at build
time by slug-based convention. Tracked under `deferred` in cross-cutting.

Make `alt_text` non-nullable in the image manifest schema (see
[`docs/rag/IMAGE_MANIFEST_SCHEMA.md`](../rag/IMAGE_MANIFEST_SCHEMA.md)).
This is both a PDF/UA-2 accessibility requirement and the data-layer
enforcement of `TRIOS_PHD_NO_IMAGE_TRAIN` (rule 02 + `trios-phd-canon`).

## 7. No-image-train via penalty, not `\clearpage`

**Status: active** — enforced by `templates/chapter.template.tex`.
The template uses `=10000` (LaTeX's `\@M`, the infinity sentinel that
forbids the break entirely) rather than `=9999` (which would allow a
last-resort break). The stricter value is intentional; do not weaken
it to 9999.

Enforce the keep-together rule for *section heading + hero/context
block + first paragraph(s)* using TeX penalties rather than hard page
breaks:

- `\widowpenalty=10000`
- `\clubpenalty=10000`
- `\needspace{}` guards on chapter openers
- `fig-pos: 'ht'` in YAML (not hard-coded `[H]`)

Hard `\clearpage` before every section is explicitly **prohibited** —
it produces short, title-only pages and excessive whitespace in
book-mode output, a known regression. (A single `\clearpage` after the
table of contents in the document template is fine — the prohibition
is on the *per-section* hard break.) See Track 4 in
[`docs/literature/04-reproducible-pdf-pipeline.md`](../literature/04-reproducible-pdf-pipeline.md).

## 8. Tectonic version pinning + reproducible-build hash

**Status: partially active** — `CreationDate` neutralisation is
**active** (verified post-v13: `pdfinfo` on the baseline PDF emits no
`CreationDate` line). sha256 verification is **active** (the
qa-brochure-pdf-checklist references `6d2e29ed…` as the accepted
baseline). The tectonic version pin in `Cargo.toml` is **planned** —
no tectonic line exists in `Cargo.toml` today; tracked under
`deferred` in cross-cutting.

- Pin the tectonic version in `Cargo.toml` and the CI environment.
- Treat a tectonic upgrade as a pipeline change requiring full QA
  re-run, not a routine dependency bump.
- Neutralise the `CreationDate` non-determinism in the LaTeX preamble.
- Add an `sha256` of the output PDF to the build log; verify it
  matches the previous accepted build for identical SSOT content.
  Divergence is a build-system regression.

## 9. Extended language scan

**Status: partially active** — the English-only scan is **active**
(rule 06 + checklist). The strong-assertion vs Open-conjecture
inconsistency detector is **planned**; tracked under `deferred` in
cross-cutting.

The language scan in [`05-brochure-qa-checklist.md`](05-brochure-qa-checklist.md)
is extended to flag two new cases:

- Non-English claim-status markers appearing in public artefacts (an
  English-only policy breach — see rule 06).
- Internal inconsistency: a claim labelled **Open conjecture** whose
  body uses strong-assertion language ("proves", "demonstrates
  conclusively", "establishes"). Either re-label or re-word; a build
  may not ship the contradiction.

---

*Canon compiled 2026-05-29; Status lines added in v14 audit
(2026-05-29) after rule 07 / cross-cutting / schema reality were
found to disagree. When relaxing or strengthening any rule here, also
update the matching synthesis in [`docs/literature/`](../literature/)
and the canon's "Recommendations" subsections to keep evidence and
rule in sync. When promoting a `planned` refinement to `active`,
update **both** this file and the matching `deferred` → `applied` tag
in `docs/literature/05-cross-cutting.md` in the same PR.*
