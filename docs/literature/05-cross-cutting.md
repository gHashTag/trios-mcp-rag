## Cross-cutting Recommendations

These bullets connect all four tracks into additions or amendments to the
existing rule files.

Each recommendation carries a v13 status tag indicating whether it was
adopted by v11 / v12 of the rule set:

- **applied** — normative rule, checklist item, or pipeline behaviour now
  exists upstream; the recommendation is reflected in current builds.
- **deferred** — still a recommendation; not yet implemented in the
  rules, schema, or CI. Open for a future wave.

- **Epistemic label propagation across the full pipeline** — **applied**
  (rules 01 + 04 enforce labels; Lua filter preserves them) —
  (`04-claim-status.md`, `01-ssot-and-derived-artifacts.md`): claim-status labels stored in Postgres
  must be emitted verbatim into every derived artefact (PDF, README, brochure).
  The Lua filter must not drop or suppress status markers during Markdown →
  LaTeX conversion. RAGAS faithfulness scoring (Track 2) and FActScore atomic
  checking (Track 3) both depend on labels surviving the pipeline
  unchanged — if a label is silently omitted, no downstream QA tool can
  detect a promoted claim.

- **Single falsification path per Open-conjecture claim** — **applied**
  (rule 04 + `trios-phd-canon.md` mandate `falsification_path`;
  QA checklist enforces it) — (`04-claim-status.md`,
  `trios-phd-canon.md`): the Popperian requirement (Track 3) and the NeSy
  V&V literature (Track 1) converge: every **Open conjecture** must state a
  conceivable disconfirming observation. Agents MUST write this path into
  the `falsification_path` Postgres column before any build. A build that
  contains **Open conjecture** claims without falsification paths must fail
  the QA checklist.

- **Postgres read-only + retrieval index hygiene** — **partially applied**
  (read-only default is in rule 03 since v9; pre-build index-presence
  check is **deferred**) — (`03-safety-railway-postgres.md`,
  `01-ssot-and-derived-artifacts.md`): structured RAG literature (Track 2)
  shows that pgvector HNSW + tsvector GIN hybrid retrieval, all within a
  single Postgres instance, delivers production-grade precision with no
  external infrastructure. The existing read-only default is correct; the
  addition is an index-presence check in the pre-build hook: if `pgvector`
  HNSW or `tsvector` GIN indexes are missing or stale, abort the build
  and report rather than silently degrading retrieval quality.

- **Alt text as a first-class schema field** — **deferred** (manifest
  schema currently requires `caption` for inline roles, but `alt_text`
  is not enforced non-nullable; no VeraPDF gate yet) —
  (`IMAGE_MANIFEST_SCHEMA.md`, `IMAGE_PLACEMENT.md`, `02-pdf-style.md`): both the PDF/UA-2 accessibility
  literature (Track 4) and the semantic anchoring rule (TRIOS_PHD_NO_IMAGE_TRAIN)
  require that every image carry a textual description tied to nearby body
  text. Making `alt_text` non-nullable in the image manifest schema enforces
  this at the data layer, not just at the rendering layer, and enables
  automated QA via VeraPDF.

- **Reproducibility hash in build artefacts** — **applied** (post-v12
  baseline sha256 `6d2e29ed…` is the canonical reference in
  `qa-brochure-pdf-checklist.md` and SKILL.md Quickstart) —
  (`00-canonical-pipeline.md`, `PDF_QA_CHECKLIST.md`): tectonic enables byte-for-byte reproducible builds
  only if the `CreationDate` non-determinism is neutralised (Track 4). Add
  a `sha256` of the output PDF to the build log and verify it matches the
  previous accepted build for identical SSOT content. Divergence is a
  build-system regression.

- **Adjacent-literature anchoring for new chapters** — **applied**
  (rule 04 caps unsupported algorithmic claims at **Open conjecture**;
  canon `trios-phd-canon.md` is the citation base) —
  (`trios-phd-canon.md`, `04-claim-status.md`): Track 1 establishes that TRIOS has no external
  peer-reviewed citation base yet. Every new chapter that makes an
  algorithmic or empirical claim must cite at least one external DOI from
  a recognised venue. Chapters without external citations are capped at
  **Open conjecture** for all their algorithmic claims, regardless of
  narrative framing.

- **RAGAS CI gate** — **deferred** (no `.github/workflows/` RAGAS job
  exists yet; checklist is manual) — (`05-brochure-qa-checklist.md`,
  `00-canonical-pipeline.md`):
  Track 2 establishes RAGAS as the standard automated RAG evaluation
  harness. A 20-question probe set drawn from the chapter corpus should be
  included in the repo (versioned, not generated) and run as part of the
  CI pipeline. Failing scores block the build in the same way that
  `pdfinfo` / `qpdf` failures currently do.

- **No-image-train enforcement via penalty, not `\clearpage`** —
  **applied** (rule 02 / IMAGE_PLACEMENT use `\widowpenalty`,
  `\clubpenalty`, `\needspace`; hard `\clearpage` per-section is
  prohibited) — (`IMAGE_PLACEMENT.md`, `02-pdf-style.md`): Track 4 (Mittelbach 2018, TeX FAQ) provides the
  formal grounding. The implementation rule is: set `\widowpenalty=9999`,
  `\clubpenalty=9999`, use `\needspace{}` guards on chapter openers, and
  use `fig-pos: 'ht'` rather than `[H]`. Hard `\clearpage` before every
  section is explicitly prohibited because it produces short pages and
  excessive whitespace in book-mode output.

- **Language scan covers claim-status labels** — **partially applied**
  (rule 06 enforces English-only public artefacts; strong-assertion
  vs Open-conjecture inconsistency detector is **deferred**) —
  (`06-language-policy.md`, `05-brochure-qa-checklist.md`): Track 3 shows that epistemic hedging
  language ("may", "appears to", "we conjecture") is a meaningful signal.
  The existing language scan should be extended to flag English-only
  claim-status markers and to detect cases where a claim body uses strong
  assertion language ("proves", "demonstrates conclusively") while carrying
  an **Open conjecture** label — that is an internal inconsistency that
  the QA checklist must catch.

- **Tectonic version pinning** — **deferred** (no tectonic version pin
  in `Cargo.toml` or CI environment as of v13 audit) —
  (`00-canonical-pipeline.md`): tectonic is
  under active development and its XeTeX engine version affects font
  metrics and therefore page layout. Pin the tectonic version in
  `Cargo.toml` / the CI environment and treat a tectonic upgrade as a
  pipeline change requiring a full QA re-run, not a routine dependency
  bump.

---

*Canon compiled: 2026-05-29 (v13 skill audit). Track 1 confirmed: no
peer-reviewed publication exists under TRIOS / S³AI / GOLDEN BRIDGE
as of this date. All citation URLs were verified against live sources
during compilation. Status tags reflect v11–v12 implementation state
at the time of this audit.*
