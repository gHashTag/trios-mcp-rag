# 00 — Canonical TRIOS PhD Pipeline

## The pipeline (the only supported path)

```
Rust TRIOS MCP / trios-phd  (Rust binary, visual PhD renderer)
        │
        │   reads chapters from Postgres (read-only)
        ▼
Railway / Postgres SSOT
        │   ssot_brochure.chapters  (or ssot.chapters)
        ▼
Markdown   (generated/build/main.md)
        │   pandoc --template chapter.template.tex
        │          --lua-filter force-fullwidth-hero.lua
        ▼
LaTeX      (generated/build/main.tex)
        │   tectonic
        ▼
PDF        (generated/out/main.pdf)
```

This pipeline is exposed in two places and only two:

- MCP tool `build_pdf` (defaults to `dry_run=true`)
- CLI subcommand `trios-mcp-rag build-pdf …`

Both wrap the same Rust code in `src/pipeline.rs`. See the README section
"SSOT → PDF pipeline" for the user-facing reference.

## What "trios-phd" / "TRIOS PhD" means

`trios-phd` is a **Rust-controlled visual PhD renderer**. Its outputs:

- carry embedded raster/vector images,
- use a book-style LaTeX template (`chapter.template.tex`),
- pass through a Lua filter (`force-fullwidth-hero.lua`) that promotes
  the per-chapter hero image to full-width,
- are typeset by `tectonic` (a self-contained TeX engine).

It is **not** a plain-text dump, not an HTML print, not a Markdown
preview, and not a corporate slide deck. The image-bearing visual
character of the PDF is part of the deliverable, not decoration.

## What an agent must NOT do

1. **Do not substitute a different renderer.** No ReportLab, no
   WeasyPrint, no wkhtmltopdf, no `pandoc … -o file.pdf` without the
   template + Lua filter, no Markdown-to-PDF online services.
2. **Do not strip images or hero panels** to make the build "simpler".
   Missing images are a build bug, not a feature.
3. **Do not bypass `tectonic`** for a system LaTeX install unless the
   user explicitly asks; reproducibility depends on tectonic's pinned
   distribution.
4. **Do not bypass the Lua filter.** The `force-fullwidth-hero` filter
   is part of the visual contract.
5. **Do not invent new SSOT tables.** The only supported tables are
   `ssot_brochure.chapters` (default) and `ssot.chapters` (fallback,
   mirror). New columns or renames require a coordinated migration
   that is out of scope for this repo.
6. **Do not run the build against production Postgres for "smoke tests".**
   Use `--dry-run` / `--check`, or point at a mirror, or use `--limit`.

## Required external binaries

- `pandoc` (tested with 3.x)
- `tectonic`

If either is missing, the agent must surface that as a blocker, not
fall back to a different tool.

## Environment variables

- `DATABASE_URL` — primary Postgres DSN, read by name only.
- `RAILWAY_SSOT_URL` — fallback DSN, read by name only.
- `--database-url-env NAME` — override which env var is consulted.

Connection strings are read from the environment by name. No DSN value
is ever logged, printed to stdout, written to a build artefact, or
committed.

## Where this rule lives

- README.md → "SSOT → PDF pipeline (`build_pdf` / `trios-mcp-rag build-pdf`)"
- `src/pipeline.rs` (Rust implementation)
- This file (normative restatement for agents)

If you read this file and find it disagrees with the code, the code is
the source of truth for *behaviour*, but this file is the source of
truth for *intent*. Reconcile before acting.
