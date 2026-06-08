# Literature Audit — Round 5 (2026-05-29)

Companion to rounds 2, 3, and 4
([`literature-audit-2026-05-29.md`](./literature-audit-2026-05-29.md),
[`...-round3.md`](./literature-audit-2026-05-29-round3.md),
[`...-round4.md`](./literature-audit-2026-05-29-round4.md)).
Triggered by maintainer request: *"next wave"* — go beyond anomaly hunting
to also surface fresh, canon-worthy primary sources from 2026.

## Scope

Two zones not covered by rounds 2–4:

1. **Track 4 (Reproducible Scholarly PDF Pipelines)** refs 1–10
   re-verified against primary sources. The Tan & Rigger ISSTA 2024
   numerical claims were already re-verified in round 3; this round
   re-verified titles, authors, venue strings, and external links.
2. **2026 publications** that strengthen Track 2 (RAG over SSOT) and
   Track 3 (claim-status / calibration). Targeted arXiv listings from
   2026-05 only.

## Findings — 1 anomaly fixed (Track 4)

| # | File | Field | Before | After (verified) |
|---|---|---|---|---|
| 1 | `04-reproducible-pdf-pipeline.md` ref 6 (Mittelbach 2018) | title + page range | "Managing forlorn orphans and widows" (paraphrase) | **"Managing forlorn paragraph lines (a.k.a. widows and orphans) in LaTeX"**, **pp. 246–251** — verified [TUGboat Vol. 39 No. 3](https://www.latex-project.org/publications/2018-FMi-TUB-tb123mitt-widows.pdf) |

## Findings — 3 next-wave references added (no further anomalies in Track 4)

| # | Track | Reference |
|---|---|---|
| T2 ref 19 | RAG over SSOT | **Budigi & Sirigiri (2026)** — "Beyond Similarity Search: A Unified Data Layer for Production RAG Systems" [arXiv:2605.03275](https://arxiv.org/abs/2605.03275). 50,000-doc controlled benchmark; PostgreSQL + pgvector + HNSW single-system data layer shows 92% latency reduction on date-filtered queries, 74% on tenant-scoped queries, 93% less sync code, zero cross-tenant leakage. Direct empirical backing for the `trios-mcp-rag` choice to keep chapters, embeddings, and tsvector inside one Postgres instance. |
| T2 ref 20 | RAG over SSOT | **Sun et al. (2026)** — "EnterpriseRAG-Bench: A RAG Benchmark for Company Internal Knowledge" [arXiv:2605.05253](https://arxiv.org/abs/2605.05253) / [GitHub](https://github.com/onyx-dot-app/EnterpriseRAG-Bench). ~500k synthetic docs across 9 enterprise source types; 500 questions across 10 categories including a "recognising when information is absent" category that maps directly onto the TRIOS abstention policy. |
| T3 ref 15 | Claim-status / calibration | **Atasoy, Mutlu, Sezer, Wahdan (ROMCIR @ ECIR 2026)** — "Do Benchmarks Underestimate LLM Performance? Evaluating Hallucination Detection With LLM-First Human-Adjudicated Assessment" [arXiv:2605.08462](https://arxiv.org/abs/2605.08462). Re-evaluating QAGS-C and SummEval with Gemini 2.5 Flash + GPT-5 Mini and a 2-adjudicator conflict-resolution pass: triple-agreement rose by 6.38% (QAGS-C) and 7.62% (SummEval); adjudicators frequently sided with the LLMs over original human labels when models supplied explicit reasoning. Reinforces the FACTS Grounding multi-judge protocol already in this canon and challenges the assumption that a single-pass human label is the ground-truth signal. |

## Verified Track 4 references — no fix needed

| Ref | Verification source |
|---|---|
| Pandoc docs (MacFarlane) | pandoc.org reachable |
| MacFarlane TUG 2020 talk title and channel | YouTube — verbatim "TUG 2020 — John MacFarlane — Pandoc for TeXnicians", uploader "TeX Users Group" |
| Tectonic Typesetting Book | tectonic-typesetting.github.io reachable |
| Tectonic Discussions #1228 | GitHub link still valid |
| Quarto Figures docs | quarto.org reachable |
| TeX FAQ widows | texfaq.org reachable |
| Overleaf accessible-PDF guide | docs.overleaf.com reachable |
| eSAIL TAMU 2025 PDF/UA-2 guide | esail.tamu.edu reachable |
| Maedje 2024 — "TeX and Typst: Layout Models" | laurmaedje.github.io — title verbatim; author "Laurenz" (Maedje is full surname, kept as-is per repo convention) |
| Tan & Rigger ISSTA 2024 — title, authors, percentages | arXiv:2407.15511 — verbatim; 0.2% / 42.1% verified verbatim |

## Why these three additions, not five

A broader scan returned three additional 2026 candidates that did **not**
meet the canon-worthiness bar:

- "When Calibrated Autonomy Becomes Impossible" (arXiv:2605.25739):
  early-stage philosophical position piece without an empirical
  contribution beyond what FELM and CHOKE already provide. **Skip.**
- "LLMs Should Express Uncertainty Explicitly" (arXiv:2604.05306): a
  pre-print version-2 that overlaps with the existing
  behaviourally-calibrated RL reference (arXiv:2512.19920). **Skip.**
- "A Principled Framework for Dynamic Abstention in LLM Generation"
  (arXiv:2604.18419 v4): same conceptual ground as Tomani 2024 and
  I-CALM, both already in the canon. **Skip.**

The three retained references each address a question the canon could
not previously answer with primary-source evidence:

- *Why single-Postgres + pgvector + HNSW is enough.* — Budigi &
  Sirigiri.
- *What an SSOT-aligned RAG probe set looks like at enterprise scale.*
  — Sun et al.
- *Whether a single human label is a reliable ground-truth signal.* —
  Atasoy et al.

## Methodology notes for future rounds

- For **YouTube and video references**, the canon's short title
  ("Pandoc for TeXnicians") is acceptable when paired with the year
  and venue ("TUG 2020 talk"), but the verbatim YouTube title should
  be at least mentioned in the audit memo for traceability.
- For **TUGboat references**, always verify both the title and the
  page range. The PDF header shows "TUGboat, Volume N (Year), No. M"
  and the page range as a footer; both are stable enough to cite.
- When **adding 2026 references**, prefer arXiv submissions whose
  abstract contains a *number* (latency reduction, accuracy gain,
  inter-rater agreement) over position pieces — the canon already has
  enough philosophical framing.

## Numbers — final state

- Track 1 (TRIOS adjacent): 8 references, unchanged
- Track 2 (RAG over SSOT): **20 references** (was 18, +Budigi, +Sun)
- Track 3 (claim-status / calibration): **15 references** (was 14,
  +Atasoy)
- Track 4 (PDF pipeline): 11 references, unchanged (Mittelbach title
  fixed in place)
- Cross-cutting: 9 recommendations, unchanged

Word count estimate: ~5,870 (was ~5,510); still a single-file canon.

---

*Prepared automatically as part of the v1.2.4 canon release.*
