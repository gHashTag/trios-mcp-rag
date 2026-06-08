# Literature Audit — Round 4 (2026-05-29)

Companion to rounds 2 and 3
([`literature-audit-2026-05-29.md`](./literature-audit-2026-05-29.md),
[`literature-audit-2026-05-29-round3.md`](./literature-audit-2026-05-29-round3.md)).
Triggered by maintainer request: *"иши аномалии и next wave"* — go after
the legacy zones that rounds 2 and 3 did not re-check.

## Scope

Re-verified, against primary sources (arXiv abstract + PDF, ACL
Anthology, OpenReview), every reference in:

- `docs/literature/02-rag-over-ssot.md` items 1–9 (Lewis, Edge GraphRAG,
  RAGAS, Datrics, CoRE, KAG, Katz, ParadeDB, RAGONITE).
- `docs/literature/03-claim-status-calibration.md` items 1–4 and 6–10
  (TruthfulQA, FActScore, FELM, HaluEval, Tomani, I-CALM, Popper 1963,
  Lassalette 2021, POPPER OpenReview). Items 5 and 11–14 already
  verified in round 2.
- Numerical claims embedded in either file (58% TruthfulQA, 48.3% FELM,
  +50–70% GraphRAG, ~84% ParadeDB, 68.8% Gemini 3 Pro FACTS, 50%
  Tomani, 30,000 HaluEval samples, +17.2% CoRE).
- `docs/agent-rules/07-literature-grounded-refinements.md` — spot check
  for embedded fabricated content (clean; no embedded references).
- Repo `README.md` and `AGENTS.md` — spot check for any
  literature-style fabricated venue or author strings (clean).

## Findings — 5 anomalies fixed

| # | File | Field | Before | After (verified) |
|---|---|---|---|---|
| 1 | `02-rag-over-ssot.md` ref 6 (KAG) | title | "KAG: Boosting LLMs via Knowledge Augmented Generation" | **"KAG: Boosting LLMs in Professional Domains via Knowledge Augmented Generation"** — verified [arXiv:2409.13731](https://arxiv.org/abs/2409.13731) |
| 2 | `02-rag-over-ssot.md` ref 9 (RAGONITE) | title | ends "...for Conversational QA" | full: **"...for Conversational QA over KGs with RAG"** — verified [arXiv:2412.17690](https://arxiv.org/abs/2412.17690) |
| 3 | `03-claim-status-calibration.md` ref 3 (FELM) | first author label | "Chern et al." | **"Chen, Zhao, Zhang, Chern et al."** — arXiv author list is Shiqi Chen, Yiran Zhao, Jinghan Zhang, I-Chun Chern, Siyang Gao, Pengfei Liu, Junxian He. I-Chun Chern is the 4th author, not the first. |
| 4 | `03-claim-status-calibration.md` ref 3 (FELM) | numerical claim | "GPT-4 F1 of only 48.3%" (implies overall benchmark F1) | **"Best evaluator (ChatGPT + retrieval) reaches only 48.3% segment-level F1 in the most favourable setting (Table 4, Content F1) — not an overall benchmark score."** The number is a single table cell, not a top-line metric. |
| 5 | `03-claim-status-calibration.md` ref 10 (POPPER OpenReview) | title + authors + venue | "POPPER: Automated Hypothesis Validation via Falsification Experiments" / no authors / "OpenReview 2025" | **Title: "Automated Hypothesis Validation with Agentic Sequential Falsifications" (POPPER); Authors: Kexin Huang, Ying Jin, Ryan Li, Michael Y. Li, Emmanuel Candes, Jure Leskovec; Venue: ICML 2025 poster.** "10× faster" restated as "10 folds" per arXiv abstract phrasing ("reducing experimental time by 10 folds"). |

## Verified verbatim — no fix needed

| Claim | Source | Status |
|---|---|---|
| Lewis et al. 2020 RAG — NeurIPS 2020 | [arXiv:2005.11401](https://arxiv.org/abs/2005.11401) | ✓ |
| Edge et al. 2024 GraphRAG title "From Local to Global..." | [arXiv:2404.16130](https://arxiv.org/abs/2404.16130) | ✓ |
| GraphRAG "+50–70% comprehensiveness" | Microsoft GraphRAG paper § 6 | ✓ (already in canon) |
| Gladkykh & Kirykov 2025 Datrics Text2SQL | [arXiv:2506.12234](https://arxiv.org/abs/2506.12234) | ✓ |
| Gu et al. 2025 CoRE +17.2% on hard tasks | [arXiv:2506.00842](https://arxiv.org/abs/2506.00842) | ✓ (verbatim) |
| TruthfulQA 58% truthfulness | [arXiv:2109.07958](https://arxiv.org/abs/2109.07958) | ✓ (verbatim, abstract) |
| FActScore EMNLP 2023 | [arXiv:2305.14251](https://arxiv.org/abs/2305.14251) | ✓ |
| HaluEval 30,000 samples | [arXiv:2305.11747](https://arxiv.org/abs/2305.11747), abstract: "30,000 hallucinated samples for the three tasks" | ✓ (verbatim) |
| Tomani 2024 — abstention reduces hallucination "up to 50%" | [arXiv:2404.10960](https://arxiv.org/abs/2404.10960) | ✓ (acceptable; wording slightly less precise than abstract, kept as-is) |
| ParadeDB ~84% retrieval precision | [paradedb.com](https://www.paradedb.com/blog/hybrid-search-in-postgresql-the-missing-manual) | ✓ |
| Gemini 3 Pro 68.8% FACTS overall | DeepMind FACTS Benchmark Suite blog | ✓ (already in canon) |
| Lassalette et al. 2021 — Intensive Care Medicine, Falsifiability in medicine | [PMC8140582](https://pmc.ncbi.nlm.nih.gov/articles/PMC8140582/) | ✓ |
| Popper 1963 "Science as Falsification" | stephenhicks.org reprint | ✓ |

## Repo-side consistency

- `docs/agent-rules/07-literature-grounded-refinements.md` — references
  the canon by *file path*, not by re-embedding any of the literature
  fields. No fabrication risk.
- `README.md` and `AGENTS.md` — no inline scientific citations; one
  reference to "FACTS Grounding 68.8%" is consistent with the canon.

## Methodology notes for future rounds

- For "X et al." citations, when the project author is *not* first,
  the agent should explicitly re-check author order on the arXiv page.
  Round 3 caught ConstraintLLM (Zhang → Shi); round 4 caught FELM
  (Chern → Chen). Same root cause: the project author or a more
  recognisable author from the team is named instead of the
  alphabetically/sequence-first author.
- For numerical claims, prefer fetching the **PDF** rather than the
  abstract page. FELM 48.3% lives only in Table 4, not in the
  abstract; quoting it as "GPT-4 F1 of only 48.3%" without table
  context is a categorisation error even though the number itself is
  correct.
- For OpenReview entries, **never** trust the venue-styled label
  inside the canon — always re-read the OpenReview page header. POPPER
  had every field (title, authors, venue) wrong because the original
  canon entry used a benchmark-name title and a generic "OpenReview
  2025" venue.

## Next wave — not actioned this round

No new references added in round 4. A 2026 release of an
"Automated-Hypothesis-Validation" successor to POPPER, or a follow-up
to FELM with a fixed overall F1 metric, would be worth picking up in
the next refresh — but no peer-reviewed paper of that profile was
found on arXiv as of 2026-05-29.

---

*Prepared automatically as part of the v1.2.3 canon release.*
