# Literature audit — 2026-05-29

This memo summarises the 2026-05-29 audit of the research canon
(`docs/literature/`) backing the operating rules.

## 1. Link audit

- 47 URLs extracted from all four track files plus `05-cross-cutting.md`.
- 45 returned `200 OK`.
- 2 transient non-blocking issues, neither requires a canon edit:
  - `https://trios-production.up.railway.app` — Railway demo dashboard
    timed out at HEAD time; treat as known intermittent.
  - `https://www.semanticscholar.org/paper/2d2623cb…` (I-CALM) — returned
    `202` (Semantic Scholar WAF / rate-limit). The arXiv preprint at
    `https://arxiv.org/abs/2604.03904` resolves cleanly when needed as a
    backup.

No canon link is broken. No URL edits were applied.

## 2. New references added (v1.2)

### Track 2 — RAG over SSOT (+8)

| # | Reference | Why it matters here |
|---|-----------|---------------------|
| 11 | [RULER (Hsieh 2024)](https://arxiv.org/abs/2404.06654) | Effective long-context retrieval window ≪ nominal window — backs chunk-sizing decisions and canary-probe design. |
| 12 | [RAGBench (Friel 2024)](https://arxiv.org/abs/2407.11005) | 100k-example, 5-domain successor to RAGAS with the TRACe metric set. |
| 13 | [ARES (Saad-Falcon 2024)](https://arxiv.org/abs/2311.09476) | Lightweight LLM-judge training + PPI confidence intervals; replaces manual judging in CI. |
| 14 | [RAGEval (Zhu 2025)](https://arxiv.org/abs/2408.01262) | Schema-driven scenario generation — methodology for growing the canary from 5 to 50+ probes from `ssot_brochure.chapters` without manual annotation. |
| 15 | [CoFE-RAG (Liu 2024)](https://arxiv.org/abs/2410.12248) | Full-chain (chunk → retrieve → rerank → generate) evaluation; matches the paragraph-aware chunker introduced in the 2026-05-29 release. |
| 16 | [HaystackCraft (Li 2025)](https://arxiv.org/abs/2510.07414) | Distractor-robustness stress test — semantically similar but factually incorrect retrievals. Not covered by the current canary. |
| 17 | [NoLiMa (Modarressi 2025)](https://arxiv.org/abs/2502.05167) | Long-context evaluation beyond literal matching; justifies dense multilingual MiniLM over BM25-only retrieval. |
| 18 | [ONERULER (Kim 2025)](https://arxiv.org/abs/2503.01996) | Multilingual RULER — relevant because the TRIOS embedder is multilingual MiniLM even though public artefacts are English-only. |

Three new rule-file recommendations were added: a 50-question scenario
canary, a RULER-style needle-in-haystack probe on chunk-size /
embedding-model changes, and a Russian-language ONERULER probe pass
before bilingual README releases.

### Track 3 — Claim-status / Calibration (+4)

| # | Reference | Why it matters here |
|---|-----------|---------------------|
| 11 | [FACTS Grounding (Jacovi et al. 2025)](https://arxiv.org/abs/2501.03200) | Two-stage automated judging (eligibility filter + multi-judge factuality); maps onto **Empirical fit** vs **Open conjecture**. |
| 12 | [FACTS Benchmark Suite (Google DeepMind 2025)](https://deepmind.google/blog/facts-benchmark-suite-systematically-evaluating-the-factuality-of-large-language-models/) | 3,513 examples across 4 factuality pillars; Gemini 3 Pro tops at 68.8% — empirical backing for "frontier-model claims are not auto-Verified". |
| 13 | [Behaviorally Calibrated RL (Wu, Liu et al. 2025–2026)](https://arxiv.org/abs/2512.19920) | Trains abstention into the model via strictly proper scoring rules; a 4B model matches frontier models on calibration. |
| 14 | [CHOKE (Simhi et al. 2025)](https://arxiv.org/abs/2502.12964) | Counter-finding: models hallucinate **with high confidence** even when they have the right knowledge. Uncertainty-based abstention alone is insufficient. |

Two new rule-file recommendations were added: adopt FACTS Grounding's
two-stage judging protocol for ungrounded LLM aggregation, and record
the FACTS Suite score (or closest analogue) of any model used to draft
chapters — frontier-LLM authorship does **not** raise claim status
above **Open conjecture** without SSOT or external-DOI corroboration.

### Track 4 — Reproducible PDF (+1)

| # | Reference | Why it matters here |
|---|-----------|---------------------|
| 11 | [Tan & Rigger ISSTA 2024](https://arxiv.org/abs/2407.15511) | Empirical study of 432 TeX documents: **0.2%** identical XeTeX vs PDFTeX, **42.1%** identical across TeX Live 2020–2023. Strong empirical backing for the tectonic version-pin rule. |

One new rule-file recommendation was added: pin the exact tectonic
version in CI, record `tectonic --version` in the build log, and treat
any TeX Live upgrade as a pipeline-breaking change requiring a fresh
`sha256` baseline of the GOLDEN CHAIN PDF.

### Track 1 — TRIOS / S³AI / GOLDEN BRIDGE

Re-verified: no new peer-reviewed publication under the exact terms
*TRIOS*, *S³AI*, or *GOLDEN BRIDGE* as an AI/ML framework name authored
by `gHashTag` or co-authors. Track 1 negative result still holds as of
2026-05-29.

## 3. Skill repackaging

`trios-research-canon` user-scope skill bumped to **v1.2**:

- `references/02-rag-over-ssot.md` — now 18 references
- `references/03-claim-status-calibration.md` — now 14 references
- `references/04-reproducible-pdf-pipeline.md` — now 11 references
- `references/canon-full.md` — regenerated (≈5,510 words, was ~4,100)
- `SKILL.md` — `version: '1.2'`, refreshed changelog and per-track
  reference counts

Skill validated with `agentskills validate` and saved (same `skill_id`
`8f48ea79-52d7-4e64-946a-f213aee4b002`).

## 4. Status

- Verified: 45 / 47 canon URLs OK (2 transient non-blocking).
- Verified: 13 new 2024–2025 references added with arXiv `200 OK`
  responses confirmed before insertion.
- Open conjecture: the new rule-file recommendations are not yet
  reflected in `docs/agent-rules/*.md` — only in the literature canon.
  Promoting them into normative rules requires a separate PR.
- Falsification path: any of the new references' headline claims (e.g.
  "0.2% identical XeTeX vs PDFTeX", "Gemini 3 Pro at 68.8%") can be
  re-verified by re-running the cited benchmark on the published code.
