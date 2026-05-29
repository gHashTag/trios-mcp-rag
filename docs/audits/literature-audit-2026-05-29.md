# Literature Canon Audit — 2026-05-29 (round 2)

> Scope: full re-audit of `docs/literature/` after the v1.2 refresh.
> Goal: verify link liveness **and** detect citation anomalies (wrong
> titles, wrong years, missing venues, duplicate entries, confused
> versions).

## Method

1. Re-extracted **all 64 URLs** from the post-v1.2 canon (vs 47 in v1.1).
2. Mass HTTP-checked every URL with a concurrent HEAD-then-GET
   fallback that demotes transient codes (202 / 403 / 405 / 429 / 5xx)
   to "verified-via-GET" before flagging.
3. Content-verified every new reference added in v1.2 (13 entries:
   8 Track-2 RAG papers, 4 Track-3 calibration papers, 1 Track-4 PDF
   reproducibility paper) by fetching the canonical arXiv page and
   extracting **title verbatim**, first author surname, year, and venue.
4. Searched for missed 2025–2026 follow-up work in GraphRAG, NeSy /
   S³AI, and abstention-learning. Found application-level variants
   (ConRAG, ArchRAG, GRASP, VerbatimRAG) but no foundational gaps —
   no canon expansion warranted.

## Findings

### Link liveness — 64 / 64 OK

- **61 / 64** returned HEAD 200 OK immediately.
- **2 / 64** returned HEAD 4xx but verified as live via GET:
  - `kaggle.com/benchmarks/google/facts-grounding` — Kaggle blocks HEAD
    requests (404 on HEAD, 200 on GET).
  - `doi.org/10.1145/3650212.3680370` — ACM Digital Library 403s on
    bots; arXiv mirror (`arxiv.org/abs/2407.15511`) verified live.
- **1 / 64** transient 502 on
  `trios-production.up.railway.app` — known maintenance window,
  non-blocking, not a canon URL (Railway-hosted demo only).

No broken links. No dead arXiv IDs. No typo'd DOIs.

### Citation anomalies — 4 errors + 2 missing venues found and fixed

| # | File | Field | Wrong in v1.2 | Correct (verified) | Source |
|---|---|---|---|---|---|
| 1 | `02-rag-over-ssot.md` line 94 | year | Zhu et al. **(2025)** "RAGEval" | **2024** (arXiv 2408.01262 = Aug 2024) | [arXiv:2408.01262](https://arxiv.org/abs/2408.01262) |
| 2 | `02-rag-over-ssot.md` line 110 | title | "HaystackCraft: Heterogeneous Retrieval-Augmented Generation Distractor Robustness" | **"Haystack Engineering: Context Engineering for Heterogeneous and Agentic Long-Context Evaluation"** (HaystackCraft = benchmark name, not paper title) | [arXiv:2510.07414](https://arxiv.org/abs/2510.07414) |
| 3 | `02-rag-over-ssot.md` line 125 | title | "ONERULER: Benchmarking Long-Context Language Models with Multilingual RULER" | **"One ruler to measure them all: Benchmarking multilingual long-context language models"** | [arXiv:2503.01996](https://arxiv.org/abs/2503.01996) |
| 4 | `03-claim-status-calibration.md` line 109 | title + acronym | "Trust Me, I'm Wrong: High-Certainty Hallucinations in LLMs" (CHOKE unexpanded) | **"Trust Me, I'm Wrong: LLMs Hallucinate with Certainty Despite Knowing the Answer"** + CHOKE = **Certain Hallucinations Overriding Known Evidence** | [arXiv:2502.12964](https://arxiv.org/abs/2502.12964) |
| 5 | `02-rag-over-ssot.md` line 70 | venue | RULER — venue omitted | **COLM 2024** | [arXiv:2404.06654](https://arxiv.org/abs/2404.06654) |
| 6 | `02-rag-over-ssot.md` line 117 | venue | NoLiMa — venue omitted | **ICML 2025** | [arXiv:2502.05167](https://arxiv.org/abs/2502.05167) |

All six entries corrected in this commit; `canon-full.md` regenerated
from the per-track files; skill mirror in
`skills-out/trios-research-canon/references/` updated.

### False alarms cleared

- **Duplicate URL warnings** — references cited in both a track's
  References section and the cross-cutting Synthesis section is the
  documented house style; not a bug.
- **"Wan et al." appearing twice in Track 1** — two distinct papers
  (Cognitive AI Systems survey + Workload Characterization),
  intentional.

## Pattern lessons

1. **Do not trust paper names from search snippets** — benchmark or
   tool names (HaystackCraft, ONERULER) frequently differ from the
   underlying paper title. Verify via `fetch_url` against the arXiv
   abstract page.
2. **Do not infer year from the arXiv ID alone** — `2408.xxxxx`
   means Aug 2024, not 2025 (mistakenly inferred from "2025 cohort").
3. **Treat HEAD 4xx as "needs GET verify", not "broken"** — Kaggle
   and ACM both block HEAD requests on indexed content pages.

## Outcome

- Skill version bumped: **1.2 → 1.2.1** (patch, corrections only).
- No references added or removed.
- No rule files (`docs/agent-rules/`) impacted; rule numbering and
  pre-build gates unchanged.
- No PDF build re-run needed — literature canon is meta-doc, not
  embedded in `ssot_brochure.chapters`.

*Audit conducted 2026-05-29.*
