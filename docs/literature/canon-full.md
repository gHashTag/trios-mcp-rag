# Research Canon for `trios-mcp-rag` Operating Rules

> **Purpose.** This document grounds the house rules of
> [gHashTag/trios-mcp-rag](https://github.com/gHashTag/trios-mcp-rag) in
> peer-reviewed and practitioner literature across four tracks. Each track
> delivers references, a synthesis, and concrete rule-file recommendations.
> A cross-cutting section ties all four tracks together.

---

---

---

## Track 1 — TRIOS / S³AI / GOLDEN BRIDGE and Adjacent Literature

### References

No peer-reviewed publication was found on arXiv, ACL Anthology, NeurIPS
Proceedings, EMNLP, SIGIR, VLDB, OpenReview, or Google Scholar that uses
the exact terms **"TRIOS"**, **"S³AI"** (self-supervised symbolic AI /
S-cubed AI), or **"GOLDEN BRIDGE"** as an AI/ML framework name authored by
`gHashTag` or any co-authors. The live PhD SSOT dashboard at
[trios-production.up.railway.app](https://trios-production.up.railway.app)
confirms the project is a practitioner compendium (88 chapters as of
2026-05-06) rather than a conference-submitted paper.

The closest adjacent literature — covering neuro-symbolic AI,
self-supervised reasoning, knowledge-grounded LLMs, and AI compendium /
textbook generation — is listed below.

1. **Wan et al. (2024) — "Towards Cognitive AI Systems: a Survey and
   Prospective on Neuro-Symbolic AI"**
   [arXiv:2401.01040](https://arxiv.org/abs/2401.01040).
   Comprehensive survey of neural + symbolic + probabilistic fusion; frames
   the motivations that the TRIOS compendium shares.

2. **Platzer (2024) — "Intersymbolic AI: Interlinking Symbolic AI and
   Subsymbolic AI"**
   [arXiv:2406.11563](https://arxiv.org/abs/2406.11563).
   Perspective piece defining a principled taxonomy for systems that move
   between symbolic meaning and neural effect — directly relevant to
   "S³AI" framing.

3. **Renkhoff et al. (2024) — "A Survey on Verification and Validation,
   Testing and Evaluations of Neurosymbolic Artificial Intelligence"**
   [arXiv:2401.03188](https://arxiv.org/abs/2401.03188) /
   [doi:10.1109/TAI.2024.3351798](https://doi.org/10.1109/TAI.2024.3351798)
   (IEEE Transactions on Artificial Intelligence).
   Reviews how symbolic components can be used to *test and validate* neural
   predictions — the V&V layer that TRIOS's claim-status framing aspires to.

4. **Wang et al. (IJRR 2025; arXiv 2024) — "Imperative Learning: A
   Self-supervised Neuro-Symbolic Learning Framework for Robot Autonomy"**
   [arXiv:2406.16087](https://arxiv.org/abs/2406.16087) (v1 Jun 2024) /
   International Journal of Robotics Research, 2025.
   Introduces a bilevel optimisation framing: neural module, symbolic
   reasoning engine, memory system — a structural parallel to TRIOS's
   Postgres SSOT + Rust renderer + LLM agent triad.

5. **Liu et al. (2025) — "SymAgent: A Neural-Symbolic Self-Learning Agent
   Framework for Complex Reasoning over Knowledge Graphs"**
   [arXiv:2502.03283](https://arxiv.org/abs/2502.03283).
   Demonstrates self-learning from KG-structured memory — a pattern
   applicable to the compendium's chapter-as-node retrieval model.

6. **Delvecchio, Molfetta, Moro (IJCAI 2025, Survey Track) —
   "Neuro-Symbolic Artificial Intelligence: A Task-Directed Survey in the
   Black-Box Models Era"** (DISI, University of Bologna)
   [IJCAI 2025 Proceedings](https://www.ijcai.org/proceedings/2025/1157.pdf).
   Provides a task-oriented NeSy taxonomy and a public reproducibility
   index for each surveyed work — a model for TRIOS's own validation
   commitments.

7. **Honda & Hagiwara (2025) — "Context-dependent neuro-symbolic AI through
   self-supervised learning with large language models"**
   [doi:10.1016/j.neucom.2025.131269](https://linkinghub.elsevier.com/retrieve/pii/S0925231225019411),
   Neurocomputing. Explores SSL for neuro-symbolic context binding.

8. **Wan et al. (ISPASS 2024) — "Workload and Characterization of
   Neuro-Symbolic AI"**
   [ISPASS 2024 PDF](https://zishenwan.github.io/publication/ISPASS24_NSAI.pdf).
   Profiles hardware bottlenecks; underscores why a Rust-native pipeline
   (rather than Python) matters for scalable symbolic document rendering.

### Synthesis

No published paper exists under the TRIOS / S³AI / GOLDEN BRIDGE name.
The project is best understood as a **practitioner knowledge compendium** —
analogous in ambition to an AI textbook generation system — whose closest
academic neighbours are neuro-symbolic AI (NeSy) surveys, knowledge-grounded
LLM pipelines, and self-learning agent frameworks over structured memory.

The NeSy literature consistently distinguishes three capability layers that
map onto the repo's own architecture: (1) a neural perception / generation
layer (the LLM and retrieval agents), (2) a symbolic reasoning / storage
layer (Postgres SSOT, chapter schema), and (3) a memory or indexing layer
(the MCP server exposing structured context). Critically, the V&V literature
(Renkhoff et al.) shows that *symbolic components are the primary mechanism
for testing neural outputs*, which grounds the repo's claim-status framing:
rather than treating LLM outputs as self-validating, the system routes every
empirical assertion through an explicit epistemic label with a declared
falsification path.

The absence of peer-reviewed publications under the TRIOS brand is itself a
data point that should be encoded in the rule files: until external
peer-review or reproduction exists, all TRIOS-specific algorithmic claims
must carry **Open conjecture** status at minimum. Prize and Nobel mentions
(referenced in `04-claim-status.md`) are particularly dangerous precisely
because no validated publication yet exists to support them.

### Recommendations

1. **Add to `04-claim-status.md`** a "publication anchor" field to each
   claim record: if no arXiv / ACL / NeurIPS / IJCAI DOI is attached, the
   maximum allowed status is **Open conjecture** regardless of narrative
   framing. Agents must refuse to upgrade status without a resolvable DOI or
   institutional preprint URL.

2. **Add to `trios-phd-canon.md`** a "NeSy positioning note": state
   explicitly that TRIOS S³AI is a practitioner NeSy compendium and link to
   the Wan et al. (2024) [arXiv:2401.01040](https://arxiv.org/abs/2401.01040)
   survey as the canonical adjacent-literature anchor. This lets agents
   answer "what is S³AI?" with grounded adjacent citations rather than
   fabricated ones.

3. **Amend `04-claim-status.md`**: add a rule that no claim may be labelled
   **Verified** unless it cites an external replication or systematic review.
   Internal consistency checks (pipeline runs, QA checklists) upgrade a
   claim to **Empirical fit** at most.

4. **Add to `00-canonical-pipeline.md`**: a "literature provenance" block in
   the chapter front-matter schema (a `refs:` YAML array in the Postgres
   row). Agents generating new chapters must populate at least one adjacent
   external citation from a recognised venue (arXiv, ACL, NeurIPS, VLDB,
   IJCAI) before the chapter can reach **Empirical fit** status.

5. **Add to `trios-phd-canon.md`**: a standing instruction that if a search
   for "TRIOS", "S³AI", or "GOLDEN BRIDGE" across arXiv / Semantic Scholar
   returns zero results, the agent must state this plainly and pivot to
   adjacent NeSy / knowledge-grounded LLM literature — never fabricate a
   match.

---

---

## Track 2 — RAG over SSOT / Structured Sources / Postgres

### References

1. **Lewis et al. (2020) — "Retrieval-Augmented Generation for
   Knowledge-Intensive NLP Tasks"**
   [NeurIPS 2020](https://proceedings.neurips.cc/paper_files/paper/2020/hash/6b493230205f780e1bc26945df7481e5-Abstract.html)
   / [arXiv:2005.11401](https://arxiv.org/pdf/2005.11401).
   The foundational RAG paper: parametric seq2seq memory + non-parametric
   dense vector index. Baseline against which all structured-RAG extensions
   are measured.

2. **Edge et al. (2024) — "From Local to Global: A Graph RAG Approach to
   Query-Focused Summarization" (Microsoft GraphRAG)**
   [arXiv:2404.16130](https://arxiv.org/abs/2404.16130);
   [Microsoft Research project page](https://www.microsoft.com/en-us/research/project/graphrag/).
   Introduces entity/relationship extraction → community detection (Leiden)
   → hierarchical summarisation. Shows +50–70% comprehensiveness on global
   questions versus flat vector RAG.

3. **Es et al. (2023) — "RAGAS: Automated Evaluation of Retrieval Augmented
   Generation"**
   [ACL EACL 2024 Demo](https://aclanthology.org/2024.eacl-demo.16/) /
   [arXiv:2309.15217](https://arxiv.org/abs/2309.15217).
   Introduces context precision, context recall, faithfulness, and answer
   relevancy as the standard RAG evaluation quartet.

4. **Gladkykh & Kirykov (2025) — "Datrics Text2SQL: A Framework for Natural
   Language to SQL Query Generation"**
   [arXiv:2506.12234](https://arxiv.org/abs/2506.12234).
   Demonstrates RAG over structured database documentation using vector
   embeddings + SQL generation; validates the Postgres-as-SSOT approach.

5. **Gu et al. (2025) — "Toward Structured Knowledge Reasoning: Contrastive
   RAG on Experience (CoRE)"**
   [arXiv:2506.00842](https://arxiv.org/abs/2506.00842).
   Proves that contrastive in-context learning over experience memory
   significantly improves Text-to-SQL and TableQA (+17.2% on hard tasks).

6. **Liang et al. (2024) — "KAG: Boosting LLMs in Professional Domains via
   Knowledge Augmented Generation"**
   [arXiv:2409.13731](https://arxiv.org/abs/2409.13731).
   Combines KG structure + vector retrieval with bidirectional LLM–KG
   enhancement. Directly relevant to `ssot_brochure.chapters` as a typed
   knowledge store.

7. **Jonathan Katz (2024) — "Hybrid search with PostgreSQL and pgvector"**
   [jkatz.github.io](https://jkatz.github.io/post/postgres/hybrid-search-postgres-pgvector/).
   Practitioner reference by a PostgreSQL core contributor showing
   pgvector + tsvector + Reciprocal Rank Fusion (RRF) patterns within a
   single Postgres instance.

8. **ParadeDB (2025) — "Hybrid Search in PostgreSQL: The Missing Manual"**
   [paradedb.com](https://www.paradedb.com/blog/hybrid-search-in-postgresql-the-missing-manual).
   Production guide for BM25 (pg_search) + pgvector HNSW hybrid; RRF fusion
   achieves ~84% retrieval precision vs ~62% for vector-only.

9. **Roy et al. (2024) — "RAGONITE: Iterative Retrieval on Induced Databases
   and Verbalized RDF for Conversational QA over KGs with RAG"**
   [arXiv:2412.17690](https://arxiv.org/abs/2412.17690).
   Two-pronged SQL + vector RAG with iterative retrieval; validates hybrid
   structured + semantic retrieval for knowledge-graph corpora.

10. **Shi et al. (EMNLP 2025) — "ConstraintLLM: A Neuro-Symbolic Framework
    for Industrial-Level Constraint Programming"**
    [ACL Anthology EMNLP 2025](https://aclanthology.org/2025.emnlp-main.809/).
    Introduces the Constraint-Aware Retrieval Module (CARM) inside a
    Tree-of-Thoughts framework with guided self-correction; the typed-retrieval
    pattern over constraint schemas is directly analogous to typed retrieval
    over the `ssot_brochure.chapters` schema.

11. **Hsieh et al. (COLM 2024) — "RULER: What's the Real Context Size of
    Your Long-Context Language Models?"**
    [arXiv:2404.06654](https://arxiv.org/abs/2404.06654).
    Synthetic long-context benchmark covering retrieval, multi-hop tracing,
    aggregation, and QA across 13 tasks; reveals that effective context for
    most production LLMs is far shorter than the advertised window.
    Relevant to the chapter-chunk sizing decision (3500 chars) and the
    canary probe set design.

12. **Friel et al. (2024) — "RAGBench: Explainable Benchmark for
    Retrieval-Augmented Generation Systems"**
    [arXiv:2407.11005](https://arxiv.org/abs/2407.11005).
    100k examples across five industry domains with the TRACe metric set
    (context relevance, utilization, completeness, adherence). Direct
    successor to RAGAS with domain coverage matching SSOT-grounded use cases.

13. **Saad-Falcon et al. (2024) — "ARES: An Automated Evaluation Framework
    for Retrieval-Augmented Generation Systems"**
    [NAACL 2024](https://aclanthology.org/2024.naacl-long.20/) /
    [arXiv:2311.09476](https://arxiv.org/abs/2311.09476).
    Trains lightweight LLM judges from synthetic data; PPI-based statistical
    confidence intervals for context relevance, answer faithfulness, and
    answer relevance. Cheaper than human eval and reusable across pipelines.

14. **Zhu et al. (2024) — "RAGEval: Scenario-Specific RAG Evaluation
    Dataset Generation Framework"**
    [arXiv:2408.01262](https://arxiv.org/abs/2408.01262).
    Generates domain-tailored QA pairs from a schema + seed documents;
    introduces Completeness / Hallucination / Irrelevance metrics. Directly
    applicable to building a TRIOS-specific RAGAS probe set from
    `ssot_brochure.chapters`.

15. **Liu et al. (2024) — "CoFE-RAG: A Comprehensive Full-chain Evaluation
    Framework for Retrieval-Augmented Generation with Enhanced Data Diversity"**
    [arXiv:2410.12248](https://arxiv.org/abs/2410.12248).
    Evaluates chunking, retrieval, reranking, and generation as one chain
    rather than as isolated stages; uses multi-granularity keywords as gold
    facts. Relevant to the paragraph-aware chunker introduced in the
    2026-05-29 release.

16. **Li, Fu et al. (2025) — "Haystack Engineering: Context Engineering for
    Heterogeneous and Agentic Long-Context Evaluation" (HaystackCraft
    benchmark)**
    [arXiv:2510.07414](https://arxiv.org/abs/2510.07414).
    Stress-tests RAG systems against semantically-similar but factually
    incorrect distractors retrieved alongside true context; a more realistic
    failure mode than missing-context evaluation. "HaystackCraft" is the
    benchmark name; the paper title is "Haystack Engineering".

17. **Modarressi et al. (ICML 2025) — "NoLiMa: Long-Context Evaluation
    Beyond Literal Matching"**
    [arXiv:2502.05167](https://arxiv.org/abs/2502.05167).
    Builds long-context benchmarks where the answer cannot be located by
    literal string match, forcing genuine semantic retrieval. Justifies
    using a dense multilingual embedder (paraphrase-multilingual-MiniLM)
    rather than BM25-only retrieval over the SSOT.

18. **Kim, Russell, Karpinska, Iyyer (2025) — "One ruler to measure them
    all: Benchmarking multilingual long-context language models" (ONERULER
    benchmark)**
    [arXiv:2503.01996](https://arxiv.org/abs/2503.01996).
    Multilingual extension of RULER showing material cross-language
    performance gaps. Directly relevant: the TRIOS embedder is multilingual
    MiniLM and the canon includes Russian-language chat / docs, even though
    public artefacts are English-only.

### Synthesis

The RAG-over-structured-sources literature converges on three findings that
directly shape how the `trios-mcp-rag` MCP server should expose the Postgres
SSOT:

**First**, flat chunk-based retrieval is insufficient for book-length corpora
with internal structure. [GraphRAG](https://arxiv.org/abs/2404.16130) and
[KAG](https://arxiv.org/abs/2409.13731) both show that hierarchical, typed
knowledge structures — exactly what `ssot_brochure.chapters` provides — yield
substantially better global comprehension than opaque vector stores. The
chapter schema is already a typed knowledge graph; the MCP server should
expose it as one.

**Second**, pure vector search loses precision on exact-match queries (chapter
numbers, claim IDs, section headings). The pgvector + tsvector hybrid
approach documented by [Jonathan Katz](https://jkatz.github.io/post/postgres/hybrid-search-postgres-pgvector/)
and [ParadeDB](https://www.paradedb.com/blog/hybrid-search-in-postgresql-the-missing-manual)
shows that RRF over both modalities in the same Postgres instance achieves
~84% precision with no external infrastructure.

**Third**, RAGAS provides a vendor-neutral evaluation harness (context
precision / recall / faithfulness / relevancy) that can be run against
pipeline output without human annotation, enabling automated regression
testing in CI. Given the repo's existing QA checklists, adding RAGAS metrics
as a programmatic gate is a natural extension. The 2024–2025 wave
([RAGBench](https://arxiv.org/abs/2407.11005),
[ARES](https://arxiv.org/abs/2311.09476),
[RAGEval](https://arxiv.org/abs/2408.01262),
[CoFE-RAG](https://arxiv.org/abs/2410.12248)) extends this from
stage-isolated metrics to **full-chain evaluation with synthetic, domain-
tailored probe generation**, and supplies the methodology for growing the
TRIOS canary set from 5 to 50+ questions without manual annotation.

**Fourth**, long-context and multilingual evaluation have matured.
[RULER](https://arxiv.org/abs/2404.06654) and
[NoLiMa](https://arxiv.org/abs/2502.05167) show that nominal context
window size systematically overstates the effective retrieval window, and
that literal-match shortcuts mask retrieval-quality regressions.
[ONERULER](https://arxiv.org/abs/2503.01996) extends this to multilingual
settings — relevant because the TRIOS embedder
(`paraphrase-multilingual-MiniLM-L12-v2`) is multilingual even though the
public artefacts are English-only.
[HaystackCraft](https://arxiv.org/abs/2510.07414) adds a distractor-
robustness dimension that the existing canary probes do not cover.

### Recommendations

1. **Add to `01-ssot-and-derived-artifacts.md`**: a clause specifying that
   the MCP server MUST expose chapter metadata (chapter ID, status, section
   heading, body text) as a **typed retrieval interface** — not as opaque
   JSONB blobs — so that both keyword (tsvector) and semantic (pgvector)
   queries can be issued against the SSOT without application-layer
   re-chunking.

2. **Add to `03-safety-railway-postgres.md`**: a retrieval index maintenance
   rule: `pgvector` HNSW and `tsvector` GIN indexes on the chapters table
   must be declared in the migration history and verified as present before
   any build is run. Index drift is a silent retrieval-quality regression.

3. **Add to `05-brochure-qa-checklist.md`**: a **RAGAS gate** step — before
   declaring a build done, run a minimum RAGAS faithfulness score (≥0.80) and
   context recall score (≥0.75) on a fixed 20-question probe set drawn from
   chapter content. Record results in the build artefact.

4. **Add to `01-ssot-and-derived-artifacts.md`**: a chunking policy for
   long chapters: each chapter row may be split into sub-chunks of ≤512
   tokens for embedding, but the `chapter_id` foreign key must be preserved
   on every chunk so that retrieved passages are always traceable back to the
   SSOT row.

5. **Add to `00-canonical-pipeline.md`**: a note that text-to-SQL queries
   issued via the MCP tool must be **read-only** (`SET TRANSACTION READ
   ONLY`) and must not use dynamic table names or unparameterised string
   interpolation. Cite [Datrics Text2SQL](https://arxiv.org/abs/2506.12234)
   as the reference pattern.

6. **Add to `trios-phd-canon.md`**: a "retrieval quality baseline" block
   documenting the accepted RAGAS metric floor. Any pipeline change that
   drops metrics below the floor must be treated as a regression and must
   not be merged without a written justification.

7. **Extend `05-brochure-qa-checklist.md`** (added 2026-05-29 audit):
   grow the RAG canary from 5 questions to a **50-question scenario
   probe set** generated via the
   [RAGEval](https://arxiv.org/abs/2408.01262) methodology from
   `ssot_brochure.chapters`. Include at least one
   [HaystackCraft](https://arxiv.org/abs/2510.07414)-style distractor
   probe per topic to surface false-positive retrievals.

8. **Add to `03-safety-railway-postgres.md`** (added 2026-05-29 audit):
   when chunk size or embedding model is changed, run the existing
   canary plus a [RULER](https://arxiv.org/abs/2404.06654)-style needle-
   in-haystack probe before merging. Effective context (RULER) often
   degrades long before nominal context (token count) does, and a chunk-
   size change can silently break long-chapter retrieval.

9. **Add to `trios-phd-canon.md`** (added 2026-05-29 audit): since the
   TRIOS embedder is multilingual, run a Russian-language probe pass
   modelled on [ONERULER](https://arxiv.org/abs/2503.01996) before any
   public release that includes the bilingual TRIOS PhD README block.
   Public artefacts remain English-only (rule 06), but the retrieval
   layer must not silently regress in the maintainer's working language.

---

---

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

---

## Track 4 — Reproducible Scholarly PDF Pipelines

### References

1. **Pandoc official documentation (MacFarlane et al., continuously
   maintained)**
   [pandoc.org](https://pandoc.org).
   The authoritative reference for the Markdown → LaTeX → PDF path. Covers
   `--pdf-engine=tectonic`, template partials, figure environment options,
   `fig-pos` specifiers, and BibTeX/CSL citation integration.

2. **MacFarlane, J. (2020) — "Pandoc for TeXnicians" (TUG 2020 talk)**
   [YouTube TUG 2020](https://www.youtube.com/watch?v=T9uZJFO54iM).
   Author's own walkthrough of pandoc's LaTeX back-end including
   `\begin{figure}` float placement, custom templates, and Lua filters.

3. **Tectonic Typesetting — Book / Introduction**
   [tectonic-typesetting.github.io](https://tectonic-typesetting.github.io/book/latest/introduction/index.html).
   Canonical documentation: XeTeX-powered, self-contained, targets
   byte-for-byte reproducible builds; embeddable as a Rust library —
   directly matching the repo's `trios-phd` integration.

4. **Tectonic GitHub Discussions — Fonts and Reproducibility #1228**
   [github.com/tectonic-typesetting/tectonic/discussions/1228](https://github.com/tectonic-typesetting/tectonic/discussions/1228).
   Documents the `CreationDate` workaround, `\let\pdfcreationdate=\creationdate`,
   and `-Z shell-escape` for reproducible builds. Directly relevant to the
   repo's byte-for-byte build requirement.

5. **Quarto documentation — Figures**
   [quarto.org/docs/authoring/figures.html](https://quarto.org/docs/authoring/figures.html).
   Comprehensive coverage of `fig-pos`, `fig-cap-location`, `fig-align`,
   subfigure layouts, and the `fig-pos: 'H'` forced placement for code
   output. Primary reference for the `IMAGE_PLACEMENT.md` rules.

6. **Mittelbach, F. (2018) — "Managing forlorn orphans and widows"**
   [TUGboat Vol. 39 No. 3](https://www.latex-project.org/publications/2018-FMi-TUB-tb123mitt-widows.pdf).
   LaTeX Project lead's definitive treatment of widow/orphan penalties and
   the `\looseness`, `\enlargethispage`, and `widows-and-orphans` package
   approaches. Grounds the repo's soft keep-together recommendation over
   hard `\clearpage` before sections.

7. **TeX FAQ — "Controlling widows and orphans"**
   [texfaq.org/FAQ-widows](https://texfaq.org/FAQ-widows).
   Community reference: `\widowpenalty`, `\clubpenalty`, finite vs infinite
   penalty settings; establishes why a soft approach (high penalty, not
   infinite) is preferable for multi-image chapter openers.

8. **LaTeX Project / Overleaf (2025) — "Creating accessible PDFs in LaTeX"**
   [docs.overleaf.com](https://docs.overleaf.com/writing-and-editing/creating-accessible-pdfs).
   TeX Live 2025 / LuaLaTeX tagged PDF workflow for PDF/UA-2 compliance;
   covers `\DocumentMetadata`, image alt text in `\includegraphics`, and
   `[H]` float placement for correct reading order.

9. **eSAIL TAMU (2025) — "Creating Accessible LaTeX PDFs: PDF/UA-2
   Compliance"**
   [esail.tamu.edu](https://esail.tamu.edu/faculty-tutorials/accessible-latex-pdf-ua-2-overleaf-2025/).
   Step-by-step guide: `\tagstructbegin`/`\tagstructend` wrappers for
   floating elements, `alt={}` in `\includegraphics`, `VeraPDF` for
   validation. Reference implementation for the repo's PDF/UA compliance
   path.

10. **Maedje, L. (2024) — "TeX and Typst: Layout Models"**
    [laurmaedje.github.io](https://laurmaedje.github.io/posts/layout-models/).
    Typst's creator compares its layout algorithm with TeX's; clarifies why
    TeX floats are algorithmically complex and what tectonic inherits from
    XeTeX's layout model.

11. **Tan & Rigger (ISSTA 2024) — "Inconsistencies in TeX-Produced
    Documents"**
    [arXiv:2407.15511](https://arxiv.org/abs/2407.15511) /
    [ISSTA 2024 DOI 10.1145/3650212.3680370](https://doi.org/10.1145/3650212.3680370).
    Large-scale empirical study of 432 TeX documents: **only 0.2% compile
    to identical output under XeTeX vs PDFTeX** and **only 42.1% produce
    identical output across TeX Live 2020–2023**. Discovered two new
    LaTeX-package bugs plus five existing bugs fixed independently of
    the study. Strong empirical backing for the **tectonic version-pin
    rule** and for treating a tectonic / TeX Live version bump as a
    pipeline-breaking change.

### Synthesis

The scholarly PDF pipeline literature reinforces every element of the repo's
pipeline choice and its `IMAGE_PLACEMENT.md` / `TRIOS_PHD_NO_IMAGE_TRAIN`
rules with formal backing:

**Reproducibility.** Tectonic's core design goal is [byte-for-byte
reproducible builds](https://tectonic-typesetting.github.io/book/latest/introduction/index.html).
The `CreationDate` discussion (#1228) identifies one remaining non-determinism
and documents the workaround. Any CI pipeline that does not apply this
workaround is not reproducible despite using tectonic. The 2024 ISSTA
study by [Tan & Rigger](https://arxiv.org/abs/2407.15511) sharpens this:
across 432 documents, only **0.2%** produced identical output between
XeTeX and PDFTeX, and only **42.1%** were identical across TeX Live
2020–2023. A tectonic / TeX Live version bump is therefore not a
maintenance event — it is a **breaking pipeline change** and must trigger
a full QA re-run plus an `sha256` re-baseline in the build log.

**Float placement.** LaTeX's float algorithm places figures in a specifier
priority order: `h` (here), `t` (top), `b` (bottom), `p` (float page). The
repo's "soft keep-together" rule — heading + hero image + first paragraph as
a unit — is technically implemented via `\begin{minipage}` or a
`{figure}[H]` with `[H]` from the `float` package. Mittelbach (2018) and the
TeX FAQ are the normative references for why infinite penalties (`\clearpage`
before every section) produce worse output (short pages, excessive whitespace)
than finite high penalties. The `TRIOS_PHD_NO_IMAGE_TRAIN` rule is exactly
this principle: do not hard-break before every image; instead keep heading,
image, and first paragraph together via a soft grouping.

**PDF/UA accessibility.** The Overleaf and eSAIL TAMU guides provide an
actionable path to PDF/UA-2 compliance: `\DocumentMetadata{tagging=on,
pdfstandard=ua-2}` + alt text on every `\includegraphics` + `[H]` float
specifiers for correct tag-tree reading order. The IMAGE_MANIFEST_SCHEMA
already captures alt text; the pipeline Lua filter should propagate it into
the generated `\includegraphics[alt={...}]` call.

**Semantic anchoring.** Quarto's `fig-pos` and caption-location system
confirms that the pandoc intermediate representation supports semantic
anchoring at the source level. The correct implementation is to set `fig-pos`
via a YAML front-matter key (not hard-coded LaTeX), making it overridable
per-chapter without touching the Lua filter.

### Recommendations

1. **Add to `IMAGE_PLACEMENT.md`**: cite Mittelbach (2018) and the TeX FAQ
   as normative references for the soft keep-together rule. Specify the
   implementation: `\begin{figure}[ht]` (not `[H]`) for hero images in the
   main text, with `\widowpenalty=9999` and `\clubpenalty=9999` in the
   preamble, combined with a `\needspace{6\baselineskip}` guard before each
   chapter opener to prevent a section heading from landing alone at the
   bottom of a page.

2. **Add to `02-pdf-style.md`**: a `CreationDate` reproducibility clause:
   the tectonic call in `pipeline.rs` MUST include the
   `\let\pdfcreationdate=\creationdate` workaround (or equivalent tectonic
   flag) so that two builds of the same SSOT content produce byte-identical
   PDFs. Failure to do so silently breaks content-hash validation.

3. **Add to `IMAGE_MANIFEST_SCHEMA.md`**: make `alt_text` a **required**
   (non-nullable) field. The Lua filter that generates `\includegraphics`
   calls must pass `alt_text` as the `alt=` keyword argument.
   Missing alt text must be a build-blocking QA error, not a warning.

4. **Add to `PDF_QA_CHECKLIST.md`**: a PDF/UA-2 validation step using
   `VeraPDF` (free, command-line): `verapdf --flavour ua2 output.pdf`.
   This is the only currently recommended tool for MathML tag validation
   per the eSAIL TAMU (2025) guide. Add the VeraPDF pass/fail output to
   the build artefact log.

5. **Add to `00-canonical-pipeline.md`**: a note that `fig-pos` for
   chapter hero images should be set to `'ht'` via the pandoc YAML
   front-matter key `fig-pos`, not via hard-coded LaTeX in the template.
   This allows per-chapter overrides without Lua filter changes and aligns
   with [Quarto's documented approach](https://quarto.org/docs/authoring/figures.html).

6. **Amend `02-pdf-style.md`**: document that tectonic uses the XeTeX
   engine and therefore requires OpenType fonts (not Type 1 / TFM) for
   correct Unicode rendering and PDF/UA compliance. Font choices must be
   declared as OTF/TTF in the LaTeX preamble, not as legacy LaTeX font
   packages.

7. **Add to `00-canonical-pipeline.md`** (added 2026-05-29 audit): pin
   the **exact tectonic version** in CI (`tectonic --version` recorded
   in the build log), and treat any tectonic / TeX Live upgrade as a
   pipeline-breaking change requiring a fresh `sha256` baseline of the
   GOLDEN CHAIN PDF. Cite
   [Tan & Rigger (ISSTA 2024)](https://arxiv.org/abs/2407.15511): only
   42.1% of documents produce identical output across TeX Live 2020–2023.
   Treat the recorded `sha256` of the PDF, not just "build succeeded",
   as the reproducibility signal.

---

---

## Cross-cutting Recommendations

These bullets connect all four tracks into additions or amendments to the
existing rule files.

- **Epistemic label propagation across the full pipeline** (`04-claim-status.md`,
  `01-ssot-and-derived-artifacts.md`): claim-status labels stored in Postgres
  must be emitted verbatim into every derived artefact (PDF, README, brochure).
  The Lua filter must not drop or suppress status markers during Markdown →
  LaTeX conversion. RAGAS faithfulness scoring (Track 2) and FActScore atomic
  checking (Track 3) both depend on labels surviving the pipeline
  unchanged — if a label is silently omitted, no downstream QA tool can
  detect a promoted claim.

- **Single falsification path per Open-conjecture claim** (`04-claim-status.md`,
  `trios-phd-canon.md`): the Popperian requirement (Track 3) and the NeSy
  V&V literature (Track 1) converge: every **Open conjecture** must state a
  conceivable disconfirming observation. Agents MUST write this path into
  the `falsification_path` Postgres column before any build. A build that
  contains **Open conjecture** claims without falsification paths must fail
  the QA checklist.

- **Postgres read-only + retrieval index hygiene** (`03-safety-railway-postgres.md`,
  `01-ssot-and-derived-artifacts.md`): structured RAG literature (Track 2)
  shows that pgvector HNSW + tsvector GIN hybrid retrieval, all within a
  single Postgres instance, delivers production-grade precision with no
  external infrastructure. The existing read-only default is correct; the
  addition is an index-presence check in the pre-build hook: if `pgvector`
  HNSW or `tsvector` GIN indexes are missing or stale, abort the build
  and report rather than silently degrading retrieval quality.

- **Alt text as a first-class schema field** (`IMAGE_MANIFEST_SCHEMA.md`,
  `IMAGE_PLACEMENT.md`, `02-pdf-style.md`): both the PDF/UA-2 accessibility
  literature (Track 4) and the semantic anchoring rule (TRIOS_PHD_NO_IMAGE_TRAIN)
  require that every image carry a textual description tied to nearby body
  text. Making `alt_text` non-nullable in the image manifest schema enforces
  this at the data layer, not just at the rendering layer, and enables
  automated QA via VeraPDF.

- **Reproducibility hash in build artefacts** (`00-canonical-pipeline.md`,
  `PDF_QA_CHECKLIST.md`): tectonic enables byte-for-byte reproducible builds
  only if the `CreationDate` non-determinism is neutralised (Track 4). Add
  a `sha256` of the output PDF to the build log and verify it matches the
  previous accepted build for identical SSOT content. Divergence is a
  build-system regression.

- **Adjacent-literature anchoring for new chapters** (`trios-phd-canon.md`,
  `04-claim-status.md`): Track 1 establishes that TRIOS has no external
  peer-reviewed citation base yet. Every new chapter that makes an
  algorithmic or empirical claim must cite at least one external DOI from
  a recognised venue. Chapters without external citations are capped at
  **Open conjecture** for all their algorithmic claims, regardless of
  narrative framing.

- **RAGAS CI gate** (`05-brochure-qa-checklist.md`, `00-canonical-pipeline.md`):
  Track 2 establishes RAGAS as the standard automated RAG evaluation
  harness. A 20-question probe set drawn from the chapter corpus should be
  included in the repo (versioned, not generated) and run as part of the
  CI pipeline. Failing scores block the build in the same way that
  `pdfinfo` / `qpdf` failures currently do.

- **No-image-train enforcement via penalty, not `\clearpage`** (`IMAGE_PLACEMENT.md`,
  `02-pdf-style.md`): Track 4 (Mittelbach 2018, TeX FAQ) provides the
  formal grounding. The implementation rule is: set `\widowpenalty=9999`,
  `\clubpenalty=9999`, use `\needspace{}` guards on chapter openers, and
  use `fig-pos: 'ht'` rather than `[H]`. Hard `\clearpage` before every
  section is explicitly prohibited because it produces short pages and
  excessive whitespace in book-mode output.

- **Language scan covers claim-status labels** (`06-language-policy.md`,
  `05-brochure-qa-checklist.md`): Track 3 shows that epistemic hedging
  language ("may", "appears to", "we conjecture") is a meaningful signal.
  The existing language scan should be extended to flag English-only
  claim-status markers and to detect cases where a claim body uses strong
  assertion language ("proves", "demonstrates conclusively") while carrying
  an **Open conjecture** label — that is an internal inconsistency that
  the QA checklist must catch.

- **Tectonic version pinning** (`00-canonical-pipeline.md`): tectonic is
  under active development and its XeTeX engine version affects font
  metrics and therefore page layout. Pin the tectonic version in
  `Cargo.toml` / the CI environment and treat a tectonic upgrade as a
  pipeline change requiring a full QA re-run, not a routine dependency
  bump.

---

*Canon compiled: 2026-05-29. Track 1 confirmed: no peer-reviewed
publication exists under TRIOS / S³AI / GOLDEN BRIDGE as of this date.
All citation URLs were verified against live sources during compilation.*

---
