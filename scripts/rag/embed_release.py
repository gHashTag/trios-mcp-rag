#!/usr/bin/env python3
"""
GOLDEN CHAIN release embedding pipeline (rule 09 audit fix).

Behaviour:
1. Connect read-only to ssot_brochure.chapters.
2. For every chapter that is either (a) missing from ssot_brochure.embeddings
   or (b) has at least one chunk whose updated_at < chapters.updated_at,
   regenerate all chunks for that chapter using the same chunker the corpus
   was built with (~3500 char windows on paragraph boundaries) and the
   canonical model sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2.
3. Upsert via INSERT ... ON CONFLICT (chapter_slug, chunk_index) DO UPDATE.
4. Print a final coverage / freshness report so the gates 9.1 and 9.2 can
   be verified.

Dry-run mode (default) writes nothing; pass --apply to commit.
"""
from __future__ import annotations
import argparse
import hashlib
import os
import re
import sys
from typing import List, Tuple

import psycopg2
from psycopg2.extras import execute_values

MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
TARGET = 3500   # target chars per chunk (matches existing corpus p50 ~3000, p90 ~3550)
HARD_MAX = 4000

# DSN is sourced from the DATABASE_URL / RAILWAY_SSOT_URL environment
# variable (rule 04: never commit DSNs, tokens, passwords, or any value
# from DATABASE_URL / RAILWAY_SSOT_URL — reference by env-var name only).
DSN = os.environ.get("DATABASE_URL") or os.environ.get("RAILWAY_SSOT_URL")


def chunk_markdown(body: str, target: int = TARGET, hard_max: int = HARD_MAX) -> List[str]:
    """Greedy paragraph-aware chunker. Never splits a paragraph; flushes when
    adding the next paragraph would push the chunk past `hard_max`, with a
    soft preference for staying near `target`."""
    paragraphs = re.split(r"\n\s*\n", body.strip())
    chunks: List[str] = []
    cur: List[str] = []
    cur_len = 0
    for p in paragraphs:
        p = p.strip()
        if not p:
            continue
        plen = len(p) + (2 if cur else 0)  # account for the joining \n\n
        if cur and cur_len + plen > hard_max:
            chunks.append("\n\n".join(cur))
            cur, cur_len = [p], len(p)
            continue
        cur.append(p)
        cur_len += plen
        if cur_len >= target:
            chunks.append("\n\n".join(cur))
            cur, cur_len = [], 0
    if cur:
        chunks.append("\n\n".join(cur))
    # if there were no paragraph breaks at all, fall back to char windows
    if not chunks and body.strip():
        s = body.strip()
        for i in range(0, len(s), target):
            chunks.append(s[i:i + target])
    return chunks


def derive_anchor(body: str) -> str:
    """Match existing corpus behaviour: the first H1/H2 line's text after #s."""
    for line in body.splitlines():
        line = line.strip()
        if line.startswith("#"):
            t = line.lstrip("#").strip()
            if t:
                return t[:200]
    # fallback: first non-blank line
    for line in body.splitlines():
        s = line.strip()
        if s:
            return s[:200]
    return "(no-anchor)"


def fetch_targets(cur) -> List[Tuple[str, str, str]]:
    """Return [(slug, body_md, updated_at)] for chapters that need re-embedding."""
    cur.execute("""
        WITH base AS (
            SELECT c.slug, c.body_md, c.updated_at,
                   COUNT(e.id)               AS n_chunks,
                   MAX(e.updated_at)         AS last_emb
            FROM ssot_brochure.chapters c
            LEFT JOIN ssot_brochure.embeddings e ON e.chapter_slug = c.slug
            WHERE c.body_md IS NOT NULL
              AND char_length(c.body_md) > 200
            GROUP BY c.slug, c.body_md, c.updated_at
        )
        SELECT slug, body_md, updated_at
        FROM base
        WHERE n_chunks = 0
           OR last_emb < updated_at
        ORDER BY (n_chunks=0) DESC, updated_at DESC
    """)
    return cur.fetchall()


def upsert_chunks(cur, slug: str, anchor: str, chunks: List[str], embeddings):
    rows = []
    for idx, (text, emb) in enumerate(zip(chunks, embeddings)):
        sha = hashlib.sha256(text.encode("utf-8")).hexdigest()
        # pgvector expects '[v1,v2,...]' string form
        vec = "[" + ",".join(f"{x:.7f}" for x in emb) + "]"
        rows.append((slug, idx, "chapter", text, sha, anchor, vec, MODEL))
    execute_values(
        cur,
        """
        INSERT INTO ssot_brochure.embeddings
            (chapter_slug, chunk_index, chunk_kind, chunk_text, sha256,
             anchor, embedding, model_name, embedded_at, created_at, updated_at)
        VALUES %s
        ON CONFLICT (chapter_slug, chunk_index) DO UPDATE SET
            chunk_kind = EXCLUDED.chunk_kind,
            chunk_text = EXCLUDED.chunk_text,
            sha256     = EXCLUDED.sha256,
            anchor     = EXCLUDED.anchor,
            embedding  = EXCLUDED.embedding,
            model_name = EXCLUDED.model_name,
            embedded_at = now(),
            updated_at = now()
        """,
        rows,
        template="(%s,%s,%s,%s,%s,%s,%s::vector,%s, now(), now(), now())",
    )


def prune_excess(cur, slug: str, kept: int):
    """If a re-embedded chapter produced fewer chunks than the previous run,
    drop the orphan indexes so 9.1 / 9.2 stay clean."""
    cur.execute(
        "DELETE FROM ssot_brochure.embeddings "
        "WHERE chapter_slug=%s AND chunk_index >= %s",
        (slug, kept),
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="commit writes")
    ap.add_argument("--only", help="comma-separated slug list to limit run")
    args = ap.parse_args()

    if not DSN:
        print("ERROR: DATABASE_URL (or RAILWAY_SSOT_URL) not set; refusing to run", file=sys.stderr)
        return 2

    print(f"[init] loading model {MODEL} ...", file=sys.stderr)
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer(MODEL)
    print("[init] model ready", file=sys.stderr)

    conn = psycopg2.connect(DSN)
    conn.autocommit = False
    cur = conn.cursor()

    targets = fetch_targets(cur)
    if args.only:
        wanted = {s.strip() for s in args.only.split(",")}
        targets = [t for t in targets if t[0] in wanted]

    print(f"[plan] {len(targets)} chapters need (re)embedding\n", file=sys.stderr)

    total_new_chunks = 0
    for slug, body, updated_at in targets:
        chunks = chunk_markdown(body)
        anchor = derive_anchor(body)
        print(f"  - {slug}: {len(body):>6} chars -> {len(chunks)} chunks  "
              f"anchor=\"{anchor[:60]}\"  (chapter updated {updated_at.date()})",
              file=sys.stderr)
        if not args.apply:
            total_new_chunks += len(chunks)
            continue
        embs = model.encode(chunks, normalize_embeddings=False, show_progress_bar=False)
        upsert_chunks(cur, slug, anchor, chunks, embs.tolist())
        prune_excess(cur, slug, len(chunks))
        total_new_chunks += len(chunks)

    if args.apply:
        conn.commit()
        print(f"\n[commit] upserted {total_new_chunks} chunks across "
              f"{len(targets)} chapters", file=sys.stderr)
    else:
        conn.rollback()
        print(f"\n[dry-run] would upsert {total_new_chunks} chunks across "
              f"{len(targets)} chapters (no writes)", file=sys.stderr)

    # gate reports
    cur.execute("""
        SELECT COUNT(*) FROM ssot_brochure.chapters c
        LEFT JOIN ssot_brochure.embeddings e ON e.chapter_slug = c.slug
        WHERE c.body_md IS NOT NULL AND char_length(c.body_md) > 200
          AND e.chapter_slug IS NULL
    """)
    print(f"[gate 9.1] chapters without embeddings: {cur.fetchone()[0]}", file=sys.stderr)

    cur.execute("""
        SELECT COUNT(*) FROM (
            SELECT c.slug
            FROM ssot_brochure.chapters c
            JOIN ssot_brochure.embeddings e ON e.chapter_slug = c.slug
            GROUP BY c.slug, c.updated_at
            HAVING MAX(e.updated_at) < c.updated_at
        ) q
    """)
    print(f"[gate 9.2] chapters with stale chunks:  {cur.fetchone()[0]}", file=sys.stderr)

    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
