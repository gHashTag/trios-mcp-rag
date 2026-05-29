# Literature Canon Audit — 2026-05-29 (round 3)

> Scope: third audit pass focused on **zones not touched in round 2**
> (Track 1 adjacent NeSy literature, Track 4 PDF pipeline references,
> older Track 2/3 entries inherited from v1.0/v1.1, cross-cutting and
> synthesis paragraphs). Round 2 only checked v1.2-new entries; this
> round checks the legacy entries plus internal consistency.

## Method

1. Read every Track file end-to-end, including synthesis and
   recommendations paragraphs (not just References blocks).
2. Cross-verified each Track 1 + Track 4 entry against arXiv / IJCAI /
   ACL Anthology / Crossref ground truth (title, first author, year,
   venue).
3. Verified the two numeric quotations in Track 4 (Tan & Rigger
   percentages) against the arXiv abstract verbatim.
4. Looked for next-wave (2025–2026) work that would genuinely extend
   the canon rather than restate existing rules.

## Findings — 7 anomalies (all fixed in this commit)

### Track 1 (adjacent NeSy literature)

| # | Entry | Wrong | Correct | Source |
|---|---|---|---|---|
| 1 | ref 2 Platzer | venue "IJCAI 2024" appended | venue removed — arXiv page does not list IJCAI; this was a fabricated venue | [arXiv:2406.11563](https://arxiv.org/abs/2406.11563) |
| 2 | ref 3 Renkhoff | venue text "IEEE Trans. AI" without DOI | DOI [10.1109/TAI.2024.3351798](https://doi.org/10.1109/TAI.2024.3351798) added, full title corrected to "...Neurosymbolic Artificial Intelligence" | arXiv page |
| 3 | ref 4 Wang Imperative Learning | "Wang et al. **(2025)**" | **(IJRR 2025; arXiv 2024)** — arXiv v1 Jun 2024; journal IJRR 2025 | [arXiv:2406.16087](https://arxiv.org/abs/2406.16087) |
| 4 | ref 6 NeSy task-directed survey | citation key "Disi-UNIBO NeSy Survey" + title "Neuro-Symbolic Artificial Intelligence: A Task-Directed Survey" | Authors: **Delvecchio, Molfetta, Moro** (DISI, University of Bologna); full title: **"Neuro-Symbolic Artificial Intelligence: A Task-Directed Survey in the Black-Box Models Era"**; venue: **IJCAI 2025 Survey Track** | [IJCAI 2025/1157](https://www.ijcai.org/proceedings/2025/1157.pdf) |
| 5 | ref 8 Wan ISPASS | title "Workload Characterization of Neuro-Symbolic AI" | Real title: **"Workload and Characterization of Neuro-Symbolic AI"** (note: "Workload AND Characterization") | [ISPASS24_NSAI.pdf](https://zishenwan.github.io/publication/ISPASS24_NSAI.pdf) |

### Track 2 (RAG over SSOT)

| # | Entry | Wrong | Correct | Source |
|---|---|---|---|---|
| 6 | ref 10 ConstraintLLM | "**Zhang** et al." | **Shi** et al. (Weichun Shi, Minghao Liu, Wanting Zhang, Langchen Shi, Fuqi Jia, Feifei Ma, Jian Zhang); also full title is "ConstraintLLM: A Neuro-Symbolic Framework for **Industrial-Level** Constraint Programming"; CARM = Constraint-Aware Retrieval Module (not generic "schema-aware retrieval") | [ACL Anthology 2025.emnlp-main.809](https://aclanthology.org/2025.emnlp-main.809/) |

### Track 3 (claim-status & calibration)

| # | Entry | Wrong | Correct | Source |
|---|---|---|---|---|
| 7 | ref 5 Xu et al. Hallucination is Inevitable | "Xu, Jain & Kankanhalli **(2025)**" | **(2024)** — v1 22 Jan 2024 | [arXiv:2401.11817](https://arxiv.org/abs/2401.11817) |

### Confirmed correct (no fix needed)

- Wan 2024 NeSy survey arXiv:2401.01040 — title, authors, year, venue all OK.
- SymAgent (Liu et al. 2025) arXiv:2502.03283 — OK.
- Honda & Hagiwara — Neurocomputing vol 654 (2025), DOI 10.1016/j.neucom.2025.131269; verified via Crossref API.
- Tan & Rigger ISSTA 2024 arXiv:2407.15511 — both numeric claims (**0.2%** XeTeX/PDFTeX, **42.1%** TeX Live 2020–2023) match the abstract verbatim.
- Xu et al. claim that hallucination is formally inevitable — confirmed from the abstract: "we formalize the problem and show that it is impossible to eliminate hallucination in LLMs".

### Next-wave scan — no expansion warranted

Foundational gaps in the canon: none found.
Recent 2025–2026 work surveyed (ConRAG, ArchRAG, GRASP, VerbatimRAG,
TruthRL, Youtu-GraphRAG) is application-level or follow-up to material
already cited (GraphRAG, HippoRAG, RAGAS). Adding them would inflate the
canon without strengthening any rule. Re-verify in 6 months.

## Pattern lessons (new in round 3)

1. **Never append a venue (conference / journal) that the arXiv landing
   page does not explicitly list.** Platzer arXiv:2406.11563 was tagged
   "IJCAI 2024" without backing — the arXiv page says nothing about
   IJCAI. This is the same failure mode as the round-2 HaystackCraft /
   ONERULER title confusion: a plausible-sounding venue/title that does
   not actually appear in the primary source.
2. **First author ≠ last-name-in-citation when project name dominates.**
   ConstraintLLM is led by **Shi**, not Zhang (Zhang appears as the
   last author). When searching for a paper by project name, always
   confirm the first author from the canonical ACL/arXiv entry.
3. **Always re-check year when an arXiv paper is later published in a
   journal/conference.** Wang Imperative Learning: arXiv v1 = Jun 2024,
   IJRR journal = 2025. The bare "(2025)" tag was misleading — both
   dates matter. Use the form `(VenueYear; arXiv Year)` when they
   diverge.
4. **Round 2 only checked v1.2-new entries.** Round 3 reveals that
   legacy v1.0/v1.1 entries (Xu, Platzer, Renkhoff, Wan-ISPASS,
   Delvecchio, ConstraintLLM) had multiple errors that survived three
   skill versions. Every future skill version should re-verify **all**
   entries, not just new ones.

## Outcome

- Skill version bumped: **1.2.1 → 1.2.2** (patch, corrections only).
- No references added or removed.
- No rule files (`docs/agent-rules/`) impacted.
- No PDF re-build needed.
- All 64+ canon URLs remain live (link liveness unchanged from round 2).

*Audit conducted 2026-05-29 (round 3).*
