#!/usr/bin/env python3
"""GOLDEN CHAIN RAG canary (rule 09.7)."""
import os, sys, psycopg2
from sentence_transformers import SentenceTransformer

# DSN is sourced from the DATABASE_URL / RAILWAY_SSOT_URL env var (rule 04).
DSN = os.environ.get("DATABASE_URL") or os.environ.get("RAILWAY_SSOT_URL")
MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"

QUERIES = [
    ("MDL / Kolmogorov", "minimum description length kolmogorov complexity formal setting"),
    ("DePIN / armoured provenance", "armoured provenance layer for decentralized physical infrastructure"),
    ("Hardware silicon anchor", "silicon anchor proof chain hardware addendum"),
    ("Three Crowns", "three crowns phi euler gamma TTSKY26b"),
    ("Adversarial critique", "devil's advocate posture methodology adversarial review"),
]
THRESHOLD = 0.45

def main():
    model = SentenceTransformer(MODEL)
    conn = psycopg2.connect(DSN)
    cur = conn.cursor()
    failures = 0
    print(f"{'query':<28} {'top1 slug':<40} {'cos':>6}  {'top2 slug':<40} {'cos':>6}")
    print("-" * 130)
    for name, q in QUERIES:
        v = model.encode([q])[0].tolist()
        vec = "[" + ",".join(f"{x:.7f}" for x in v) + "]"
        cur.execute(
            "SELECT chapter_slug, chunk_index, 1 - (embedding <=> %s::vector) AS cos "
            "FROM ssot_brochure.embeddings ORDER BY embedding <=> %s::vector LIMIT 2",
            (vec, vec),
        )
        rows = cur.fetchall()
        (s1, _, c1), (s2, _, c2) = rows[0], rows[1]
        mark = "" if c1 >= THRESHOLD else " <-- BELOW THRESHOLD"
        print(f"{name:<28} {s1:<40} {c1:>6.3f}  {s2:<40} {c2:>6.3f}{mark}")
        if c1 < THRESHOLD:
            failures += 1
    conn.close()
    print(f"\n[canary] {len(QUERIES)} queries, {failures} below {THRESHOLD}")
    return 0 if failures == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
