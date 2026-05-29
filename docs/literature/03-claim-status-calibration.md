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

3. **Chen, Zhao, Zhang, Chern et al. (2023) — "FELM: Benchmarking Factuality
   Evaluation of Large Language Models"**
   [NeurIPS 2023 D&B Track](https://neurips.cc/virtual/2023/poster/73491) /
   [arXiv:2310.00741](https://arxiv.org/abs/2310.00741).
   Fine-grained segment-level annotation across math, world-knowledge, and
   reasoning. Best evaluator (ChatGPT + retrieval) reaches only **48.3%
   segment-level F1** in the most favourable setting (Table 4, Content
   F1) — not an overall benchmark score; retrieval-augmented evaluators
   still underperform across most segments and domains.

4. **Li et al. (2023) — "HaluEval: A Large-Scale Hallucination Evaluation
   Benchmark"**
   [EMNLP 2023](https://aclanthology.org/2023.emnlp-main.397/) /
   [arXiv:2305.11747](https://arxiv.org/abs/2305.11747).
   30,000 task-specific hallucination samples across QA, dialogue, and
   summarisation; provides hallucination taxonomy that maps to
   **High-risk** and **Retracted** claim statuses.

5. **Xu, Jain & Kankanhalli (2024) — "Hallucination is Inevitable: An
   Innate Limitation of Large Language Models"**
   [arXiv:2401.11817](https://arxiv.org/abs/2401.11817) (v1 22 Jan 2024).
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

10. **Huang, Jin, R. Li, M. Y. Li, Candes, Leskovec (ICML 2025) —
    "Automated Hypothesis Validation with Agentic Sequential Falsifications"
    (POPPER)**
    [OpenReview iTevNo8PzG](https://openreview.net/forum?id=iTevNo8PzG).
    Agentic framework that designs sequential falsification experiments for
    free-form hypotheses, reducing experimental time by **10 folds** on
    biological domains while preserving Type-I error control. ICML 2025
    poster.

11. **Jacovi et al. (2025) — "The FACTS Grounding Leaderboard: Benchmarking
    LLMs' Ability to Ground Responses to Long-Form Input" (Google DeepMind /
    Google Research / Kaggle)**
    [arXiv:2501.03200](https://arxiv.org/abs/2501.03200) /
    [DeepMind blog](https://deepmind.google/blog/facts-grounding-a-new-benchmark-for-evaluating-the-factuality-of-large-language-models/) /
    [Kaggle leaderboard](https://www.kaggle.com/benchmarks/google/facts-grounding).
    1,719 prompts (860 public / 859 private) with 32k-token documents;
    two-stage automated judging (eligibility filter + multi-judge
    factuality aggregation) to resist leaderboard hacking. Directly maps
    to TRIOS **Empirical fit** vs **Open conjecture**: a claim is
    Empirical fit only if it is grounded in the SSOT context, not in
    parametric memory.

12. **Google DeepMind (2025) — "FACTS Benchmark Suite" (Grounding v2 +
    Parametric + Search + Multimodal)**
    [DeepMind blog](https://deepmind.google/blog/facts-benchmark-suite-systematically-evaluating-the-factuality-of-large-language-models/).
    3,513 examples across four factuality pillars; Gemini 3 Pro tops the
    suite at 68.8% overall — i.e. even the frontier model is wrong about
    a third of the time across these benchmarks. Empirical backing for
    the TRIOS rule that **frontier-model claims are not auto-Verified**:
    they require SSOT corroboration or an external DOI.

13. **Wu, Liu et al. (2025–2026) — "Mitigating LLM Hallucination via
    Behaviorally Calibrated Reinforcement Learning"**
    [arXiv:2512.19920](https://arxiv.org/abs/2512.19920).
    Shows that standard RLVR with binary rewards trains models as
    "good test-takers" — i.e. to guess whenever P(correct) > 0. Trains
    models against strictly proper scoring rules so they output a
    calibrated probability of correctness, then abstain or flag
    individual claims when uncertain. A 4B Qwen3 model trained this way
    matches Grok-4 / Gemini-2.5-Pro on SimpleQA calibration despite
    much lower factual accuracy. Direct mechanistic backing for the
    **TRIOS abstention policy**: prefer "Open conjecture" + falsification
    path over a confidently-wrong upgrade to Verified.

14. **Simhi, Itzhak, Barez, Stanovsky, Belinkov (2025) — "Trust Me, I'm
    Wrong: LLMs Hallucinate with Certainty Despite Knowing the Answer"
    (CHOKE = Certain Hallucinations Overriding Known Evidence)**
    [arXiv:2502.12964](https://arxiv.org/abs/2502.12964).
    Demonstrates that models can hallucinate **with high certainty even
    when they possess the correct knowledge** ("CHOKE" cases), and that
    uncertainty-based abstention methods fail on this subset. Important
    counterweight to I-CALM and Tomani: TRIOS must not rely on model-
    declared certainty alone — the **SSOT lookup + external-DOI check**
    must remain mandatory, even when the model sounds confident.

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
conjecture** rather than silently promoted. The 2025–2026
[behaviorally-calibrated RL work](https://arxiv.org/abs/2512.19920) goes
further: it trains the abstention behaviour into the model itself by
rewarding strictly proper scoring rules, showing that a 4B model so
trained matches frontier models on calibration metrics. The cautionary
counter-finding is [Simhi et al.'s CHOKE result](https://arxiv.org/abs/2502.12964):
models also hallucinate with **high** confidence even when they have the
right knowledge. Hence TRIOS keeps the **SSOT + external-DOI lookup as
mandatory**, not as a fallback for low-confidence outputs.

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
   and the
   [behaviorally-calibrated RL paper](https://arxiv.org/abs/2512.19920)
   as the evidence base, and explicitly note the
   [CHOKE counter-finding](https://arxiv.org/abs/2502.12964): high model
   confidence is **not** a sufficient signal for upgrading a claim — a
   source lookup is still required.

7. **Add to `04-claim-status.md`** (added 2026-05-29 audit): adopt the
   [FACTS Grounding](https://arxiv.org/abs/2501.03200) two-stage
   judging protocol — (1) eligibility filter (does the answer address
   the request?), then (2) multi-judge factuality — as the recommended
   automated check for chapters that aggregate ungrounded LLM output.
   A single judge model is leaderboard-hackable; aggregating multiple
   judges is the field-standard mitigation.

8. **Add to `trios-phd-canon.md`** (added 2026-05-29 audit): for any
   external-LLM-assisted draft of a chapter, record the
   [FACTS Benchmark Suite](https://deepmind.google/blog/facts-benchmark-suite-systematically-evaluating-the-factuality-of-large-language-models/)
   score of the model used (or, for unscored models, the closest
   leaderboard analogue). Even Gemini 3 Pro reaches only **68.8%**
   overall on the FACTS Suite — frontier-LLM authorship of a draft
   **does not** raise the claim status of its assertions above
   **Open conjecture** without SSOT or external-DOI corroboration.

---

