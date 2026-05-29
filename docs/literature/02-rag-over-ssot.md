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

6. **Liang et al. (2024) — "KAG: Boosting LLMs via Knowledge Augmented
   Generation"**
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
   and Verbalized RDF for Conversational QA"**
   [arXiv:2412.17690](https://arxiv.org/abs/2412.17690).
   Two-pronged SQL + vector RAG with iterative retrieval; validates hybrid
   structured + semantic retrieval for knowledge-graph corpora.

10. **Zhang et al. (EMNLP 2025) — "ConstraintLLM: A Neuro-Symbolic Framework
    for Constraint Programming"**
    [ACL Anthology EMNLP 2025](https://aclanthology.org/2025.emnlp-main.809).
    Demonstrates schema-aware retrieval (CARM module) inside a ToT
    framework; relevant to typed chapter-schema retrieval.

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

