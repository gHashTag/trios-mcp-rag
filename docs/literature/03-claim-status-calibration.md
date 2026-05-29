## Track 3 — Claim-Status, Calibration, and Falsifiability for LLM Outputs

### References

1. **Lin, Hilton & Evans (2022) — "TruthfulQA: Measuring How Models Mimic
   Human Falsehoods"**
   [ACL 2022](https://aclanthology.org/2022.acl-long.229/) /
   [arXiv:2109.07958](https://arxiv.org/abs/2109.07958).
   817 adversarial questions; top models were truthful only 58% of the time.
   Establishes that model size alone does not improve truthfulness — a
   foundational argument for explicit claim labelling.

2. **Min et al. (2023) — "FActScore: Fine-grained Atomic Evaluation of
   Factual Precision in Long Form Text Generation"**
   [EMNLP 2023](https://aclanthology.org/2023.emnlp-main.741/) /
   [arXiv:2305.14251](https://arxiv.org/abs/2305.14251).
   Decomposes generation into atomic facts and checks each against a
   knowledge source. The atomic-fact decomposition maps cleanly onto
   individual claims within a TRIOS chapter.

3. **Chern et al. (2023) — "FELM: Benchmarking Factuality Evaluation of
   Large Language Models"**
   [NeurIPS 2023 D&B Track](https://neurips.cc/virtual/2023/poster/73491) /
   [arXiv:2310.00741](https://arxiv.org/abs/2310.00741).
   Fine-grained segment-level annotation across math, world-knowledge, and
   reasoning; GPT-4 F1 of only 48.3% shows retrieval-augmented evaluators
   still underperform.

4. **Li et al. (2023) — "HaluEval: A Large-Scale Hallucination Evaluation
   Benchmark"**
   [EMNLP 2023](https://aclanthology.org/2023.emnlp-main.397/) /
   [arXiv:2305.11747](https://arxiv.org/abs/2305.11747).
   30,000 task-specific hallucination samples across QA, dialogue, and
   summarisation; provides hallucination taxonomy that maps to
   **High-risk** and **Retracted** claim statuses.

5. **Xu, Jain & Kankanhalli (2025) — "Hallucination is Inevitable: An
   Innate Limitation of Large Language Models"**
   [arXiv:2401.11817](https://arxiv.org/abs/2401.11817).
   Formal proof (via learning theory) that hallucination cannot be eliminated.
   Grounds the repo's design decision to label rather than suppress
   uncertain claims.

6. **Tomani et al. (2024) — "Uncertainty-Based Abstention in LLMs Improves
   Safety and Reduces Hallucinations"**
   [arXiv:2404.10960](https://arxiv.org/abs/2404.10960).
   Shows abstention over uncertain samples reduces hallucination by up to
   50%; justifies the "I don't know / Open conjecture" tier.

7. **Zong et al. (2026) — "I-CALM: Incentivizing Confidence-Aware
   Abstention"**
   [Semantic Scholar 2d2623cb](https://www.semanticscholar.org/paper/2d2623cb2cda8630b4d5e0c05741acaeacedfedd).
   Prompt-only framework for epistemic abstention; shows a clear
   abstention–hallucination frontier, relevant to automated QA gating.

8. **Popper, K. (1963) — "Science as Falsification"** (lecture, republished)
   [PDF via stephenhicks.org](http://www.stephenhicks.org/wp-content/uploads/2018/09/PopperK-Science-as-Falsification.pdf).
   The canonical statement: "A theory which is not refutable by any
   conceivable event is non-scientific. Irrefutability is not a virtue."
   Grounds the mandatory falsification path for **Open conjecture** claims.

9. **Lassalette et al. (2021) — "Falsifiability in medicine: what clinicians
   can learn from Karl Popper"**
   [Intensive Care Medicine](https://pmc.ncbi.nlm.nih.gov/articles/PMC8140582/).
   Translates Popperian falsifiability into a practitioner rubric that
   cleanly maps to the five-level TRIOS claim taxonomy.

10. **OpenReview (2025) — POPPER: Automated Hypothesis Validation via
    Falsification Experiments**
    [OpenReview iTevNo8PzG](https://openreview.net/forum?id=iTevNo8PzG).
    AI agent that designs falsification experiments for free-form hypotheses;
    10× faster than human scientists on biological domains.

### Synthesis

The hallucination and calibration literature establishes three things that
bear directly on `04-claim-status.md`:

**One — labelling is necessary and provably sufficient in design.** Because
hallucination is formally unelimitable ([Xu et al.](https://arxiv.org/abs/2401.11817)),
the only responsible strategy is explicit epistemic labelling, not
suppression. The five-tier TRIOS scheme (Verified / Empirical fit / Open
conjecture / High-risk / Retracted) mirrors the rubrics used by FELM and
HaluEval, which operate at segment level — fine-grained enough to annotate
individual claims within a chapter paragraph.

**Two — abstention and the "I don't know" response are measurable.** The
I-CALM and abstention-based hallucination reduction literature shows that
prompt-level mechanisms can shift error-prone cases to abstention with near
zero computational overhead. This justifies a soft rule: any agent-generated
content that lacks a verifiable source should be flagged as **Open
conjecture** rather than silently promoted.

**Three — prize and Nobel claims are uniquely dangerous.** TruthfulQA
specifically documents that models parrot authority-based falsehoods
("X won the Nobel Prize for Y") with high confidence. The existing
`04-claim-status.md` prohibition on using Nobel/prize claims as validation
proxies is empirically grounded: no benchmark in the literature accepts
award citations as evidence of factual correctness.

The Popperian framework operationalises the **Open conjecture** label:
a claim is Open conjecture if and only if a falsification path — a
conceivable experiment or measurement that could refute it — is stated
alongside it. Claims without a stated falsification path should be
automatically downgraded to **High-risk**.

### Recommendations

1. **Amend `04-claim-status.md`**: add a mandatory `falsification_path`
   field to every **Open conjecture** and **Empirical fit** claim. A claim
   without a stated falsification path (a conceivable experiment or
   observation that would refute it) must be auto-downgraded one level.
   Cite [Popper (1963)](http://www.stephenhicks.org/wp-content/uploads/2018/09/PopperK-Science-as-Falsification.pdf)
   as the formal grounding.

2. **Amend `04-claim-status.md`**: add a "hallucination taxonomy" mapping
   section cross-referencing HaluEval categories to TRIOS levels: intrinsic
   hallucination (contradicts source) → **Retracted**; extrinsic
   hallucination (unverifiable) → **Open conjecture** or **High-risk**
   depending on risk impact.

3. **Add to `05-brochure-qa-checklist.md`**: a "claim density gate" — each
   chapter must have no more than 15% of its sentences carrying no explicit
   claim-status label. Unlabelled sentences in technical sections are treated
   as implicitly **Open conjecture** and flagged for manual review.

4. **Amend `04-claim-status.md`**: prohibit the phrase "Nobel Prize" as
   evidence in any claim justification field. Replace with a note citing
   [TruthfulQA](https://aclanthology.org/2022.acl-long.229/) as to why
   authority-based claims are an unreliable validation signal.

5. **Add to `trios-phd-canon.md`**: a "calibration baseline" section: any
   agent-generated batch of ≥50 claims must pass a FActScore-style atomic
   check against the SSOT before publication. This can be implemented as a
   pre-build hook in the pipeline that queries the chapters table and
   spot-checks 10% of atomic facts.

6. **Add to `04-claim-status.md`**: an "abstention policy" — if an agent
   cannot identify a source in the SSOT or an external DOI to support a
   claim, it MUST write `[Open conjecture — source not located]` and halt
   rather than promote to a higher status. Cite
   [I-CALM](https://www.semanticscholar.org/paper/2d2623cb2cda8630b4d5e0c05741acaeacedfedd)
   as the evidence base.

---

