# scripts/rag — release-time RAG gates

Operational scripts that implement the gates from
[`docs/agent-rules/09-audit-and-rag-coverage.md`](../../docs/agent-rules/09-audit-and-rag-coverage.md).

Both scripts read the DSN from `DATABASE_URL` (or `RAILWAY_SSOT_URL`)
per rule 04 — never commit or print the DSN; reference it by env-var
name only.

## `embed_release.py`

Paragraph-aware (re-)embedding pipeline. Targets every chapter that is
either missing from `ssot_brochure.embeddings` (gate 9.1) or has at
least one chunk whose `updated_at < chapters.updated_at` (gate 9.2),
then upserts via
`INSERT … ON CONFLICT (chapter_slug, chunk_index) DO UPDATE`.

```bash
# dry-run (default — writes nothing)
DATABASE_URL='...' python3 scripts/rag/embed_release.py

# apply
DATABASE_URL='...' python3 scripts/rag/embed_release.py --apply

# limit to specific slugs
DATABASE_URL='...' python3 scripts/rag/embed_release.py --apply \
  --only unified-symmetry-article,fm-13-depin-positioning
```

The pipeline prints the gate 9.1 / 9.2 counts after the run; both must
be zero for a GOLDEN CHAIN release.

Model: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`
(384-dim) — the canonical SSOT model. Do not change the model without
re-embedding every row, or you will silently mix two metric spaces.

Backups before any write run: snapshot `ssot_brochure.embeddings` to
`ssot_brochure.embeddings_backup_<YYYYMMDD>_<reason>` per rule 03.

## `rag_canary.py`

Five-query retrieval smoke test that the release process runs after
every embedding-table write (gate 9.7). Exit code 1 if any top-1
cosine is below 0.45.

```bash
DATABASE_URL='...' python3 scripts/rag/rag_canary.py
```

Add new queries by editing the `QUERIES` list; pick targets that
exercise distinct chapter clusters (e.g. MDL/compression,
DePIN/economics, hardware/co-design).
