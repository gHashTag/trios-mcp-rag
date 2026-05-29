# Research Canon — `docs/literature/`

This directory holds the literature canon backing the operating rules
in [`docs/agent-rules/`](../agent-rules/). It is grouped into four
tracks plus a cross-cutting recommendations file. See
[`docs/agent-rules/07-literature-grounded-refinements.md`](../agent-rules/07-literature-grounded-refinements.md)
for the normative rules derived from this canon.

| File | Track |
|------|-------|
| [`00-overview.md`](00-overview.md) | Purpose and scope |
| [`01-trios-s3ai-adjacent.md`](01-trios-s3ai-adjacent.md) | Track 1 — TRIOS / S³AI / GOLDEN BRIDGE search result (negative as of 2026-05-29) + adjacent neuro-symbolic / self-supervised reasoning literature |
| [`02-rag-over-ssot.md`](02-rag-over-ssot.md) | Track 2 — RAG over SSOT / structured Postgres sources |
| [`03-claim-status-calibration.md`](03-claim-status-calibration.md) | Track 3 — Claim-status, calibration, falsifiability for LLM outputs |
| [`04-reproducible-pdf-pipeline.md`](04-reproducible-pdf-pipeline.md) | Track 4 — Reproducible scholarly PDF pipelines |
| [`05-cross-cutting.md`](05-cross-cutting.md) | 9 cross-track recommendations mapped to specific rule files |
| [`canon-full.md`](canon-full.md) | Single-file copy of the entire canon (~4,100 words) |

*Canon compiled 2026-05-29; refreshed 2026-05-29 (v1.2 audit). Track 1
negative result is dated — re-verify before citing as evidence in any
public artefact.*

## Changelog

- **v1.2 (2026-05-29)** — 47-URL link audit (45 OK, 2 transient
  non-blocking); +8 RAG 2024–2025 papers in Track 2 (RULER, RAGBench,
  ARES, RAGEval, CoFE-RAG, HaystackCraft, NoLiMa, ONERULER); +4
  calibration / factuality references in Track 3 (FACTS Grounding,
  FACTS Benchmark Suite, Behaviorally Calibrated RL, CHOKE); +1 PDF
  reproducibility reference in Track 4 (Tan & Rigger ISSTA 2024 on
  TeX cross-engine and cross-version inconsistencies).
- **v1.1 (2026-05-29)** — +2 cross-cutting recommendations driven by
  the GOLDEN CHAIN audit: build-time SQL coverage / freshness gates,
  schema-level `alt_text` CHECK constraint.
- **v1.0 (2026-05-29)** — initial 4-track canon.

