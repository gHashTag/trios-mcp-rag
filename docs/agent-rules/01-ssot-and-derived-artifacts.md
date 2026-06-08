# 01 — SSOT and Derived Artifacts

## Single Source of Truth

The SSOT for the GOLDEN BRIDGE / TRIOS S³AI compendium is the Postgres
table on Railway:

- Primary: `ssot_brochure.chapters`
- Mirror / fallback: `ssot.chapters`

Schema (live Railway / Postgres, post-v12 build — verify before any DDL):

```sql
CREATE TABLE ssot_brochure.chapters (
    slug              TEXT PRIMARY KEY,
    kind              TEXT NOT NULL,
    order_key         INT  NOT NULL,
    title             TEXT NOT NULL,
    body_md           TEXT NOT NULL,
    illustration_url  TEXT,                        -- nullable; URL or NULL
    sha256            TEXT,                        -- recomputed by W38 trigger
    word_count        INT NOT NULL DEFAULT 0,      -- recomputed by W38 trigger
    byte_size         INT,                         -- octet_length(body_md)
    format            TEXT,                        -- 'md' default
    asset_sha         TEXT,                        -- FK to assets registry
    updated_at        TIMESTAMPTZ DEFAULT now()    -- bumped by W38 trigger
);
```

**Schema verification before any DDL is mandatory.** Run:

```bash
psql "$DATABASE_URL" -c '\d ssot_brochure.chapters'
```

The live table is authoritative; this file documents the post-v12
shape but is **not** the source of truth — a migration may have added
or renamed columns since this rule was last updated. The cross-session
bootstrap (`docs/agents/agent-bootstrap.md`) explains the three SSOT
access paths (Pipedream connector, local mirror from TSV snapshot,
local `.env` DSN). The local TSV mirror at
`docs/agents/ssot-snapshot/chapters-post-v12.tsv` carries only the
render-essential columns (slug, kind, order_key, title, body_md,
illustration_url) and is sufficient for read-only RAG; the W38 trigger
columns (`sha256`, `word_count`, `byte_size`, `updated_at`) live only
in the Railway primary.

Anything that does not live in (or derive from) this table is **not**
the SSOT, even if it looks authoritative.

## Derived artefacts (not SSOT)

The following are render targets / projections of the SSOT. They can
and should be rebuilt from the SSOT; they must never be hand-edited and
then back-ported casually.

- `README.md` (this repo and the parent `gHashTag/trios` repo)
- Generated Markdown (`generated/build/main.md`)
- Generated LaTeX (`generated/build/main.tex`)
- Generated PDF (`generated/out/main.pdf`)
- Brochures, one-pagers, marketing PDFs
- Articles, blog posts, social media excerpts
- Any "exported" or "published" copy of a chapter

## Agent contract

1. **Treat derived artefacts as outputs.** If an agent finds a
   discrepancy between an artefact and the SSOT, the SSOT wins —
   propose updating the artefact, not the SSOT, unless the user
   explicitly asks to change the SSOT.
2. **Never copy text out of a derived artefact and back into the SSOT
   without confirmation.** Drift accumulates quickly that way.
3. **When asked to "update the brochure" or "fix the PDF",** the
   default path is: change the SSOT, rebuild via the canonical
   pipeline. Direct edits to generated files are only appropriate as
   one-shot, clearly-labelled emergencies, and must be reflected back
   into the SSOT in the same session.
4. **Do not invent a new "source of truth" file** (e.g.
   `final-brochure-v2.md`) in the repo. That creates a second
   authoritative copy and re-introduces the drift problem this rule
   exists to prevent.

## Why this matters

The compendium has 80+ chapters. Without an enforced SSOT, parallel
edits in README / brochure / PDF / chat snippets diverge silently. The
RAG tools (`search_chapters`, `get_chapter`, `list_chapters`,
`forbidden_audit`) read directly from Postgres for this reason — they
are intentionally one query away from authoritative text.
