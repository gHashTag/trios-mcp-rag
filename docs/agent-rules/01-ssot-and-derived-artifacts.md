# 01 — SSOT and Derived Artifacts

## Single Source of Truth

The SSOT for the GOLDEN BRIDGE / TRIOS S³AI compendium is the Postgres
table on Railway:

- Primary: `ssot_brochure.chapters`
- Mirror / fallback: `ssot.chapters`

Schema (from README.md):

```sql
CREATE TABLE ssot_brochure.chapters (
    slug        TEXT PRIMARY KEY,
    kind        TEXT NOT NULL,
    order_key   INT NOT NULL,
    title       TEXT NOT NULL,
    body_md     TEXT NOT NULL,
    word_count  INT NOT NULL DEFAULT 0
);
```

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
