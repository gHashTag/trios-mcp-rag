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
as a programmatic gate is a natural extension.

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

---

