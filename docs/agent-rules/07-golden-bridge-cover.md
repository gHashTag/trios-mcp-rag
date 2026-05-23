# 07 — Golden Bridge Cover Canon and Cover-Asset Handoff

This rule fixes the canonical TRIOS PhD / GOLDEN BRIDGE cover artwork and
the way a selected cover asset is handed off into the PDF pipeline. It
exists so that future agents and RAG retrievals can find — by exact,
grep-friendly anchor — what the cover must look like, what must not
replace it, and how to wire a chosen cover into the canonical build.

The anchors below are intentionally stable, ALL-CAPS, underscore-joined
identifiers. Do **not** rename them. RAG indexes, agent prompts, and
internal tooling key on these strings verbatim.

---

## TRIOS_PHD_CANONICAL_PIPELINE

The only supported render path for the TRIOS PhD / GOLDEN BRIDGE
brochure PDF is:

```
trios-phd  →  Railway / Postgres SSOT  →  Markdown  →  pandoc  →  LaTeX  →  tectonic  →  PDF
```

- `trios-phd` is the Rust visual PhD renderer in this repo (see
  `src/pipeline.rs`, MCP tool `build_pdf`, CLI subcommand
  `trios-mcp-rag build-pdf`).
- The SSOT is the Postgres `ssot_brochure.chapters` (or `ssot.chapters`)
  table on Railway. It is read-only by default.
- Markdown is generated under `generated/build/main.md`.
- `pandoc` uses `chapter.template.tex` and the
  `force-fullwidth-hero.lua` filter.
- LaTeX is typeset by `tectonic` (pinned, self-contained TeX engine).
- The PDF lands at `generated/out/main.pdf`.

Do **not** substitute ReportLab, WeasyPrint, wkhtmltopdf, a Markdown-to-PDF
web service, a plain `pandoc … -o file.pdf` without the template and Lua
filter, a system LaTeX install in place of tectonic, or any
"corporate brochure" template. See
[00-canonical-pipeline.md](00-canonical-pipeline.md) for the full
pipeline rule.

A cover asset (image file) enters this pipeline as the **first page**
(see `ASSET_HANDOFF` below). The pipeline itself does not change.

---

## GOLDEN_BRIDGE_COVER_CANON

The canonical TRIOS PhD / GOLDEN BRIDGE cover is the user-selected
**GPT Image 2 v3** style, based on the previous TRIOS / *Flos Aureus*
cover. Its visual identity is fixed:

- **Background**: black velvet / chalkboard texture. Deep, matte black.
  Not glossy, not photographic, not corporate flat black.
- **Title**: deep antique gold calligraphic title. Hand-drawn /
  engraved-feeling letterforms, warm gold (not bright yellow, not
  metallic-CGI gold).
- **Annotations**: white chalk Leonardo da Vinci-style formulas and
  diagrams scattered around the composition — geometric constructions,
  ratios, hand-style mathematical marginalia.
- **Central emblem**: three microchips arranged as the central emblem
  (the "three strands" of the TRIOS S³AI compendium, rendered as
  silicon).
- **Authors**: the byline reads
  `Dmitrii Vasilev · Stergios Pellis · Scott Olsen`
  in that order, using middle-dot separators.
- **Bottom ribbon**: a `TRINITY S3AI` ribbon along the bottom of the
  cover.

This is the canonical cover. If the user has not explicitly requested
a one-shot variant for the current build, the renderer / agent uses
this cover. Variants are session-scoped overrides, not new defaults.

### Relationship to the prior in-repo cover defaults

The pre-existing `02-pdf-style.md` § "Cover" wording — *"white academic
title page is the default"* — was the renderer's plain-LaTeX titlepage
fallback (produced by the `build_cover` tool in `src/main.rs`). The
`GOLDEN_BRIDGE_COVER_CANON` described here is the **canonical
image-based cover** that supersedes that fallback when a cover asset
exists for the build. The plain-LaTeX titlepage remains a valid
fallback when no image asset has been selected. Do not confuse the two:
the fallback is not a license to replace the canonical cover.

---

## DO_NOT_REBUILD_WITH_GENERIC_CODE

Once a `GOLDEN_BRIDGE_COVER_CANON` asset has been selected for a build,
the agent MUST NOT replace it with any of the following without an
**explicit, in-session** user instruction for the current build:

- A CAD or vector UI cover (Figma export, Illustrator template,
  generic vector "title slide").
- A ReportLab-generated cover, or any other generic Python-PDF cover.
- A corporate brochure cover (teal banner, gradient block, marketing
  layout, full-bleed colour, stock photography).
- An "assembled flat layout" composed at build time from logos,
  rectangles, and stock text blocks.
- A regenerated GPT image with a different style prompt.
- The plain-LaTeX `build_cover` titlepage when an image asset exists
  and is part of the current build.

"Make it look cleaner", "modernise the cover", "polish the design", and
similar vague aesthetic requests are **not** valid overrides. A valid
override looks like:

- "For this brochure only, use a white academic titlepage."
- "Swap the cover to the alt v4 prompt I sent — just this build."

If the user has not said something that specific, keep the canonical
cover.

---

## COVER_TEXT_RISK

Text rendered by GPT Image 2 (or any image-generation model) inside the
cover artwork is **visually acceptable for cover art**, but it is
**not** a substitute for typeset publication metadata.

Implications:

- Author names, the title, the date, the version string, and any
  formulas that must be exactly correct (e.g. the
  `\varphi^2 + \varphi^{-2} = 3` anchor) are validated and rendered in
  the LaTeX / PDF pipeline, not trusted from the cover bitmap.
- If the GPT image's text differs from the SSOT-authoritative title /
  author / version, the SSOT wins. The cover image is decorative for
  those fields, not authoritative.
- For the *publication record* — PDF metadata, the colophon / imprint
  page, the bibliographic block — use SSOT-driven LaTeX. Never copy a
  date or formula off a cover bitmap into the manuscript.
- If an agent notices that the cover bitmap's text and the SSOT
  disagree on author order, title, version, or formula content, flag
  it as drift and surface both values. Do not silently align the SSOT
  to the bitmap.

In short: the cover is allowed to have visually rendered text, but the
canonical text lives in the SSOT and the LaTeX pipeline.

---

## SECRET_SAFETY

Public repository documents MUST NOT contain Railway / Postgres URLs,
tokens, passwords, environment-variable values, image-generation API
keys, or any value pulled from a Railway "Variables" tab.

Refer to such values by **environment variable name only**:

- `DATABASE_URL` — primary Postgres DSN.
- `RAILWAY_SSOT_URL` — fallback Postgres DSN.
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc. — by name only.

This applies to:

- Markdown / LaTeX / Lua / Rust source.
- Generated build artefacts (`generated/build/main.md`,
  `generated/build/main.tex`, `generated/out/main.pdf` metadata).
- Commit messages, PR descriptions, agent chat output that may be
  logged or shared.
- README, AGENTS.md, `docs/`, and any in-repo prompt or rule file.

The Rust pipeline in this repo already follows this contract (see
README → "Production safety" and
[03-safety-railway-postgres.md](03-safety-railway-postgres.md)). The
cover handoff path described in `ASSET_HANDOFF` must follow it too:
cover assets are referenced by repository-relative path or by SSOT row
id, never by a credentialed URL.

---

## ASSET_HANDOFF

When a `GOLDEN_BRIDGE_COVER_CANON` cover asset has been selected, it
enters the canonical pipeline as the **first page** of the PDF. The
handoff has three parts: where the asset lives, how it is recorded,
and how it is rendered.

### 1. Where the cover asset lives

- The selected cover asset is stored under a stable
  repository-relative path. Recommended location:

  ```
  assets/covers/golden-bridge/<version>/<image_id>.<ext>
  ```

  for example:

  ```
  assets/covers/golden-bridge/v27/cover-golden-bridge-gpt-image-2-v3.png
  ```

- `<image_id>` MUST be a stable, kebab-case identifier (consistent
  with `docs/rag/IMAGE_PLACEMENT.md` § "SSOT image identity
  contract"). The id encodes the cover lineage
  (`cover-golden-bridge-gpt-image-2-v3`), not the prompt iteration
  number — re-running the same canonical prompt does not change the
  id; only a deliberate canon change does.
- Large binary covers should follow whatever LFS / asset-store
  convention the repo uses at the time of the build. Do not commit
  multi-MB binaries casually; coordinate with the maintainer.

### 2. How the cover asset is recorded

The cover row in the SSOT image manifest (or its in-repo equivalent)
uses:

| Field                   | Value (canonical cover)                                                   |
|-------------------------|---------------------------------------------------------------------------|
| `image_id`              | `cover-golden-bridge-gpt-image-2-v3` (or successor canonical id)          |
| `role`                  | `cover`                                                                   |
| `canonical_anchor`      | `front-cover` (or the equivalent title-page anchor used by the template)  |
| `section_id`            | `front-cover`                                                             |
| `priority`              | `0` (cover always wins its anchor)                                        |
| `caption`               | empty (cover art is not captioned)                                        |
| `source` / `path`       | repository-relative path under `assets/covers/golden-bridge/<version>/…`  |
| `file_hash`             | sha256 of the binary asset                                                |
| `allowed_repeat_policy` | `title_page_only`                                                         |

See `docs/rag/IMAGE_PLACEMENT.md` for the full identity contract; the
table above is the cover-specific instantiation.

### 3. How the cover asset becomes the first page

The cover is the **first page of the PDF**, rendered before chapter 1
and before any front-matter generated by the template's plain-LaTeX
titlepage. Two acceptable mechanisms, in order of preference:

1. **Template-driven cover page**: the LaTeX template
   (`chapter.template.tex`, or a thin wrapper) opens with a single
   full-bleed `\includegraphics` of the cover asset on a dedicated
   page, before `\maketitle` / any title block. The cover page has no
   page number and no running header.
2. **Pandoc include-before**: if the template route is not feasible,
   use `pandoc --include-before-body=<cover.tex>` where `cover.tex`
   contains the same `\includegraphics` block. This must still flow
   through tectonic.

Either way:

- The cover asset is referenced **by repository-relative path**, not
  by a credentialed URL.
- The cover is treated as `role = cover` with
  `allowed_repeat_policy = title_page_only`; it MUST NOT also appear
  as a chapter hero.
- If no cover asset has been selected for the build, fall back to the
  plain-LaTeX `build_cover` titlepage. Do not invent a substitute
  cover, do not paste a chapter hero into the cover slot, and do not
  emit a corporate / generic cover (see `DO_NOT_REBUILD_WITH_GENERIC_CODE`).

### 4. QA expectations for the cover

After a cover-bearing build, QA (per
[05-brochure-qa-checklist.md](05-brochure-qa-checklist.md) and
[../qa/brochure-pdf-checklist.md](../qa/brochure-pdf-checklist.md))
expects:

- Exactly one cover page, page 1, image-dominant.
- The cover page is the single accepted "image-heavy / low-context"
  candidate in the hero-anchoring scan (consistent with the accepted
  baseline in `docs/rag/trios-phd-canon.md` § 3).
- No duplicate cover image elsewhere in the PDF.
- No leaked DSN, token, or credential in the cover-related LaTeX or
  in the PDF metadata (see `SECRET_SAFETY`).

---

## Cross-references

- [00-canonical-pipeline.md](00-canonical-pipeline.md) — pipeline rule
  (TRIOS_PHD_CANONICAL_PIPELINE expanded).
- [02-pdf-style.md](02-pdf-style.md) — visual-style rule; cover
  overrides described there are session-scoped.
- [03-safety-railway-postgres.md](03-safety-railway-postgres.md) —
  secrets discipline (SECRET_SAFETY expanded).
- [05-brochure-qa-checklist.md](05-brochure-qa-checklist.md) — QA
  checklist; cover page is the accepted single low-context candidate.
- [../rag/IMAGE_PLACEMENT.md](../rag/IMAGE_PLACEMENT.md) — SSOT image
  identity contract; the cover row conforms to it.
- [../rag/trios-phd-canon.md](../rag/trios-phd-canon.md) — RAG canon;
  this rule's anchors are intended to be retrievable verbatim.
