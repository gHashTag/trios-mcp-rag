# Literature Audit — Round 6 (2026-05-29)

**Scope.** Verify zones not covered in rounds 2–5 of the literature canon
audit: Track 1 references 6–8 (legacy NeSy entries beyond the round-3
sweep), `05-cross-cutting.md`, and a fresh 2026 sweep for both Track 1
(neuro-symbolic) and Track 4 (PDF pipeline). Add canon-worthy 2026
references where the bar — *"answers a question that existing canon refs
don't"* — is cleared.

**Result.** No new anomalies in Track 1 refs 5–8 or in `05-cross-cutting.md`.
**One canon-worthy 2026 reference added to Track 1** (NeuSymMS).
Zero changes to Tracks 2, 3, 4. Total canon refs: 9 (T1) + 20 (T2) + 15
(T3) + 11 (T4) = **55 references + 9 cross-cutting recommendations**.

---

## Verification results (Round 6)

### Track 1 — refs 5–8 spot-check

| # | Entry | Status | Notes |
|---|-------|--------|-------|
| 5 | Liu et al. (2025) — SymAgent, arXiv:2502.03283 | OK | Author order Liu/Zhang/Lin/Yang/Peng/Yin confirmed. |
| 6 | Delvecchio, Molfetta, Moro (IJCAI 2025, Survey Track) | OK | Authors + venue + track + PDF URL all verified against the IJCAI 2025 Proceedings index. |
| 7 | Honda & Hagiwara (2025), Neurocomputing | OK | Elsevier `linkinghub` redirector blocked by IP filter from the audit sandbox; falls back to the bibliography reproduction at scik.org which lists: *"Context-Dependent Neuro-Symbolic AI Through Self-Supervised Learning with Large Language Models"*, **Neurocomputing 654 (2025) 131269**. Canon entry uses lowercase title casing; this is a stylistic difference from the journal's title-case rendering, not a citation error, and is consistent with how Tracks 2 and 4 render long titles. No fix needed. |
| 8 | Wan et al. (ISPASS 2024) | OK | Title was corrected to verbatim form in round 3 (*"Workload and Characterization of Neuro-Symbolic AI"*); re-confirmed. |

### Cross-cutting (`05-cross-cutting.md`)

Re-read the file end-to-end. **No external citations** — every link is a
relative pointer to a rule file in the parent repo
(`00-canonical-pipeline.md`, `01-ssot-and-derived-artifacts.md`,
`02-pdf-style.md`, `03-safety-railway-postgres.md`, `04-claim-status.md`,
`05-brochure-qa-checklist.md`, `06-language-policy.md`,
`trios-phd-canon.md`, `IMAGE_PLACEMENT.md`, `IMAGE_MANIFEST_SCHEMA.md`,
`PDF_QA_CHECKLIST.md`). All 9 recommendations remain internally consistent
with the rule files they reference (last verified in round 4). Nothing
to fix.

### Track 4 — 2026 sweep

Searched arXiv / Google Scholar for new 2026 work on Typst-vs-LaTeX,
PDF/UA-2 accessibility, and reproducible PDF builds. The strongest hits
restated findings already covered by Tan & Rigger ISSTA 2024
(arXiv:2407.15511) on byte-identical TeX output, by Maedje 2024 on
typesetting differentials, and by the eSAIL / Overleaf PDF/UA-2 guides
already in Track 4. **Nothing canon-worthy added.** The Track 4 entry
count remains 11.

---

## New reference added (Round 6)

### Track 1, ref 9 — NeuSymMS (Sultan, Thuraisamy, Rajaratnam, 2026)

> Sultan, M.; Thuraisamy, S.; Rajaratnam, D. (2026).
> *NeuSymMS: A Hybrid Neuro-Symbolic Memory System for Persistent,
> Self-Curating LLM Agents.*
> [arXiv:2605.17596](https://arxiv.org/abs/2605.17596) — cs.AI,
> submitted 2026-05-17.

**Why it crosses the canon-worthy bar.**

1. **Closest 2026 production-NeSy parallel to the TRIOS architecture
   that exists in the public literature.** Both systems use a relational
   database as the symbolic layer (TRIOS uses `ssot_brochure.chapters`;
   NeuSymMS uses `subject–relation–value` triples) with an LLM as the
   neural extractor and explicit lifecycle rules controlling promotion,
   deduplication, and pruning.
2. **CLIPS-based expert system for classification, deduplication, and
   reconciliation under explicit lifecycle rules.** This is the
   operational counterpart to the TRIOS claim-status labels (Verified /
   Empirical fit / Open conjecture / High-risk / Retracted) — a
   precedent in production NeSy work for routing every fact through an
   explicit rule-based gate rather than a learned classifier.
3. **Dual-horizon short-term / long-term memory model with access-based
   promotion and time-based pruning.** Provides a concrete published
   pattern for the *promotion path* between an editable working chapter
   and the canonical SSOT row — something the existing TRIOS rules
   describe procedurally but did not previously have an external
   anchor for.
4. **User / agent / agent-to-agent scoping.** Aligns with the
   read-only-by-default Postgres SSOT rule and the planned
   per-agent ledger discipline.

**What it does NOT establish.** NeuSymMS is itself an arXiv preprint
(not yet peer-reviewed at a venue with PC review), so it cannot be used
to upgrade any TRIOS claim past **Empirical fit**. It is cited as
adjacent literature, in the same status tier as the other Track 1 entries
(Wan 2024, Platzer 2024, Renkhoff 2024, Wang IJRR 2025, Liu 2025,
Delvecchio IJCAI 2025, Honda Neurocomputing 2025, Wan ISPASS 2024).

**Anomaly guard.** The NeuSymMS abstract discusses a baseline system
(REMem) and quotes its numbers (e.g. 3.4% / 13.4% memory-retention
deltas in REMem's own ablations). Those numbers belong to REMem, **not
NeuSymMS**, and are deliberately omitted from the canon entry to avoid
the same mis-attribution risk that round 4 caught with the FELM 48.3%
figure.

---

## Candidates considered and rejected (Round 6)

- **Generic 2026 "agentic memory" preprints.** Multiple recent
  preprints describe LLM-agent memory systems but either (a) lack a
  symbolic component (RAG-only), (b) describe key-value stores without
  triple structure, or (c) discuss summarisation-only memory. None
  add a capability or framing that the NeuSymMS entry doesn't already
  capture. Rejected as duplicative.
- **2026 PDF accessibility surveys.** Restate the PDF/UA-2 obligations
  already covered by the Overleaf and eSAIL guides in Track 4. No new
  rule implication. Rejected.
- **2026 Typst-vs-LaTeX comparisons.** Restate Maedje 2024's layout
  analysis and Tan & Rigger ISSTA 2024's byte-reproducibility findings.
  Rejected.

---

## Summary

- **Files changed:** `docs/literature/01-trios-s3ai-adjacent.md`
  (added ref 9 — NeuSymMS), `docs/literature/canon-full.md`
  (regenerated), `docs/audits/literature-audit-2026-05-29-round6.md`
  (this memo).
- **Canon size:** Track 1 8 → 9; Track 2 = 20; Track 3 = 15;
  Track 4 = 11; cross-cutting = 9 recs. **Total 55 references.**
- **Word count:** 5,870 → **6,027** (canon-full.md).
- **Verification:** no anomalies in Track 1 legacy refs 5–8 or
  cross-cutting. 2026 PDF sweep returned no canon-worthy candidates.

*Compiled 2026-05-29 (round 6). Next-wave guidance: re-verify all Track 1
arXiv links every 90 days; NeuSymMS will need a venue-publication
status check by 2026-08-29.*
