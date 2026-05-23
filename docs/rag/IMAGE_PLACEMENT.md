# TRIOS PhD Image Placement & Dedup Rules

<!-- RAG anchors (grep-friendly, do not remove): -->
<!-- TRIOS_PHD_IMAGE_PLACEMENT -->
<!-- TRIOS_PHD_IMAGE_DEDUP -->
<!-- TRIOS_PHD_CANONICAL_PIPELINE -->
<!-- TRIOS_PHD_RENDERER_FIRST -->
<!-- TRIOS_PHD_STYLE_LOCK -->

This document is the **single source of truth for image placement** in the TRIOS PhD / brochure pipeline. Future agents (Claude Code, Cursor, Windsurf, opencode, and any MCP-RAG consumer) MUST read this before editing chapters, the manifest, the LaTeX template, the Lua filter, or the generated PDF.

The rules here exist because the TRIOS S3AI brochure has repeatedly shipped with **duplicated and misplaced hero images**. The root cause has consistently been a missing contract between (a) how images are stored in the SSOT and (b) how the renderer chooses where to place them. This file encodes that contract.

---

## 1. Canonical pipeline (TRIOS_PHD_CANONICAL_PIPELINE)

```
Rust TRIOS MCP / trios-phd
        │  (writes/maintains)
        ▼
Railway / Postgres SSOT  (ssot_brochure.chapters, image manifest rows)
        │  read-only
        ▼
Markdown (generated/build/main.md)
        │  pandoc --template chapter.template.tex
        │         --lua-filter force-fullwidth-hero.lua
        ▼
LaTeX   (generated/build/main.tex)
        │  tectonic
        ▼
PDF     (generated/out/main.pdf)
```

There is exactly **one** supported renderer chain: **SSOT → Markdown → pandoc → LaTeX → tectonic → PDF**. No Python / ReportLab substitute. No manual post-processing of the PDF.

**Production safety:**
- The pipeline is **read-only** against Railway/Postgres SSOT. Never `INSERT`/`UPDATE`/`DELETE`.
- No DSN value, token, or password is ever logged, printed, committed, or embedded in docs. Use placeholders (`postgresql://user:password@host:5432/dbname`) only.
- Public repo docs are English-only.

## 2. Style lock (TRIOS_PHD_STYLE_LOCK)

The PDF look is fixed and must not be redesigned ad-hoc:

- White academic PhD title page.
- Serif typography throughout.
- Large black-and-white engraved / ornamental TRIOS S3AI hero panels.
- Standard book margins.
- Large images (full text-width or full page where role allows).

Forbidden substitutes (these have all happened before and must be rejected on review):
- Generic ReportLab or text-only PDFs.
- Teal / corporate cover layouts.
- Black covers.
- Color photography or rasterized stock art in place of engraved panels.

If the style appears wrong, fix the **template / SSOT image record**, not the exported PDF.

## 3. Renderer-first principle (TRIOS_PHD_RENDERER_FIRST)

**Never edit the PDF directly.** If something is wrong in the PDF, it is wrong in one of these, in order of suspicion:

1. SSOT image manifest (`image_id`, `role`, `canonical_anchor`, `priority`, `allowed_repeat_policy`).
2. Chapter Markdown (anchor mismatch, missing reference, accidental duplicate link).
3. Pandoc Lua filter (`filters/force-fullwidth-hero.lua`).
4. LaTeX template (`templates/chapter.template.tex`).
5. Renderer flags / build config in `src/pipeline.rs`.

A patched PDF will be silently regenerated next build. Fix the source.

---

## 4. SSOT image identity contract (TRIOS_PHD_IMAGE_PLACEMENT)

Every image used by the brochure pipeline MUST be represented as one logical row in the SSOT image manifest (or an equivalent table joined to `ssot_brochure.chapters`). The following fields are required:

| Field                    | Type    | Required | Purpose |
|--------------------------|---------|----------|---------|
| `image_id`               | text    | yes      | Stable, unique, kebab-case identifier (e.g. `hero-trios-s3ai-engraving-01`). The renderer keys on this — never reuse for a different visual. |
| `role`                   | enum    | yes      | One of: `title`, `cover`, `part_opener`, `chapter_hero`, `evidence_figure`, `local_diagram`, `logo`, `watermark`, `reference_plate`. |
| `canonical_anchor`       | text    | yes      | Section / chapter slug or claim id where this image first belongs (e.g. `ch-03-symmetry`, `part-ii-opener`). Must match an existing section in the SSOT. |
| `section_id`             | text    | yes      | Resolved section identifier the renderer uses to place the image. Usually equals `canonical_anchor`; may resolve to a sub-section for `evidence_figure` / `local_diagram`. |
| `priority`               | int     | yes      | Lower wins when two images compete for the same anchor. Stable tiebreaker for deterministic ordering. |
| `caption`                | text    | yes      | Human-readable caption. Empty string is **not** allowed for `evidence_figure` or `local_diagram`. |
| `source` / `path`        | text    | yes      | Repository-relative path or asset URI. Must resolve. |
| `file_hash`              | text    | yes      | Content hash (sha256). Used by dedup. |
| `allowed_repeat_policy`  | enum    | yes      | One of: `none` (default, image may appear at most once), `every_part_opener`, `every_chapter_opener`, `title_page_only`, `watermark`, `reference_plate`. Anything other than `none` MUST be justified by `role`. |

Rows that fail this contract MUST be rejected by the loader (or excluded with a warning) rather than rendered into the PDF.

---

## 5. Deterministic placement rules (TRIOS_PHD_IMAGE_PLACEMENT)

The renderer MUST follow these rules. They are deterministic; identical SSOT input must produce identical PDF output.

1. **One hero per major part / chapter.** A given `part_opener` / `chapter_hero` may appear exactly once unless its `allowed_repeat_policy` explicitly permits repetition.
2. **No adjacent reuse of `image_id`.** The same `image_id` MUST NOT appear in two adjacent sections (previous, current, or next). Adjacency is computed on the rendered order, not the SSOT `order_key`.
3. **No orphan images.** Every image MUST be anchored to a section, claim, or chapter via `canonical_anchor`. An image with no resolvable anchor is dropped (with a warning), not floated to an arbitrary position.
4. **Anchor-before-image (with role exceptions).** A figure MUST NOT be placed before its first textual reference (its first-use anchor). Exceptions: `role ∈ {title, cover, part_opener}` may precede textual content because the cover/part-opener page IS the anchor.
5. **First-use order, then priority.** Within a chapter, images render in the order their `canonical_anchor` is first hit in the body Markdown. Ties (multiple images at the same anchor) are broken by `priority` ascending, then `image_id` lexicographic.
6. **Role-driven sizing is fixed.** `title`, `cover`, `part_opener`, `chapter_hero` → full text-width hero (or full page where the template defines). `evidence_figure`, `local_diagram` → in-line, captioned. The renderer must not promote a `local_diagram` to a hero or vice versa.

## 6. Dedup rules (TRIOS_PHD_IMAGE_DEDUP)

These checks MUST run before a build is considered green:

1. **Duplicate `image_id`.** The manifest must have a unique-on-`image_id` constraint. Two rows with the same id → error.
2. **Duplicate `file_hash` with different `image_id`.** Treat as a warning; collapse to a single id unless intentionally distinct framings exist.
3. **Duplicate `source` / `path`.** Same file referenced by two ids → warning; fix the SSOT.
4. **Duplicate `caption`.** Identical non-empty caption across two non-watermark images → warning; usually a copy-paste bug.
5. **Adjacent role repetition.** Two `chapter_hero` images of the same `image_id` in consecutive chapters → error. Two visually similar but distinct `image_id`s adjacent → warning to confirm intent.
6. **Allowed exceptions** (and only these):
   - `role = title` with `allowed_repeat_policy = title_page_only` — title-page hero / logo.
   - `role = watermark` with `allowed_repeat_policy = watermark` — page watermark on every page.
   - `role = reference_plate` with `allowed_repeat_policy = reference_plate` — fold-out / appendix plate referenced multiple times.

Any "duplicate" not covered by an exception is a defect in the SSOT or Markdown, not a rendering oddity to be tolerated.

## 7. Logical ordering rules

For each part of the brochure, the visual sequence MUST be:

```
title hero        (role = title, once, title-page only)
  └─► part opener (role = part_opener, once per part)
        └─► chapter hero (role = chapter_hero, once per chapter)
              └─► evidence figures (role = evidence_figure, in first-use order)
                    └─► local diagrams (role = local_diagram, near their reference)
```

Concretely:
- A `chapter_hero` MUST appear before any `evidence_figure` in the same chapter.
- An `evidence_figure` MUST appear at or after its first textual reference.
- A `local_diagram` MUST appear within the section that references it; never floated to the next chapter.
- Do NOT place visuals before their first textual anchor unless `role ∈ {cover, title, part_opener}`.

---

## 8. QA gates (run BEFORE sharing or committing the PDF)

These are blocking. A build that fails any of them is not "the brochure"; it's a draft.

1. **Markdown scan.** Grep the generated Markdown (`generated/build/main.md`) for repeated image references:
   ```bash
   grep -nE '!\[[^]]*\]\([^)]+\)' generated/build/main.md \
     | awk -F'[()]' '{print $2}' | sort | uniq -c | sort -rn | head
   ```
   Anything with count > 1 that is not in the allowed-exception list above is a defect.

2. **LaTeX scan.** Grep the generated LaTeX (`generated/build/main.tex`) for repeated `\includegraphics`:
   ```bash
   grep -oE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' generated/build/main.tex \
     | sort | uniq -c | sort -rn | head
   ```
   Same rule: counts > 1 outside the exception list = defect.

3. **Order check.** Diff "image order in the manifest, restricted to rendered chapters" against "image order in the generated LaTeX". They must agree, modulo declared priority and first-use ordering.

4. **PDF text/image audit (if `pdftotext` / `pdfimages` are available).**
   ```bash
   pdfimages -list generated/out/main.pdf | awk 'NR>2 {print $1, $2, $3, $4}' | sort | uniq -c
   pdftotext -layout generated/out/main.pdf - | head -200
   ```
   Look for repeated image objects on adjacent pages and confirm title-page text matches the expected style lock.

5. **Title page inspection.** Open page 1 and the first body page. Confirm: white background, serif title, ornamental engraved S3AI panel, standard margins. Reject teal / black / corporate variants.

6. **First body pages inspection.** Open the first 3–5 body pages. Confirm chapter hero is the chapter's declared `chapter_hero`, not the previous chapter's image bled forward.

If any gate fails, do **not** patch the PDF. Go to the failure mode guidance.

## 9. Failure mode guidance

When duplicates or misplacement are found, fix in this order:

1. **SSOT image manifest** — most defects originate here. Wrong `canonical_anchor`, wrong `priority`, or missing `allowed_repeat_policy` flag.
2. **Chapter Markdown body** — accidental duplicate image link, image referenced before its anchor, or image referenced from the wrong chapter.
3. **Pandoc Lua filter** (`filters/force-fullwidth-hero.lua`) — only if the renderer is promoting / demoting roles incorrectly.
4. **LaTeX template** (`templates/chapter.template.tex`) — only if the issue is layout (margins, sizing, page breaks), not selection.
5. **Build config** (`src/pipeline.rs`) — only if the order / filter wiring itself is broken.

**Never** fix duplication by editing the exported PDF or by hand-deleting figures from `main.tex` after pandoc has produced it; both will regenerate on the next build.

---

## 10. Likely root cause of historical duplication

Based on the current repo state (SSOT has chapters but no separate image manifest table; `render_markdown` in `src/pipeline.rs` emits chapter bodies verbatim; the Lua filter `force-fullwidth-hero.lua` promotes hero images by heuristic), the recurring duplicate / misplaced-image symptom most likely comes from:

1. **No `image_id` discipline.** The same physical image is referenced from multiple chapter bodies via raw Markdown `![](path)` links, with no unique id to dedup on.
2. **No `canonical_anchor`.** Images are emitted wherever the body Markdown happens to mention them, so a chapter that mentions the previous chapter's hero re-emits it.
3. **No `role` distinction in the source.** `force-fullwidth-hero.lua` cannot tell a `chapter_hero` from a `local_diagram`, so it may promote the wrong figure to full width and leave the real hero in-line.
4. **No QA gate before share.** Drafts have been shared straight from `tectonic` without running the Markdown / LaTeX dedup grep, so duplicates only surface visually.

The fix is structural: enforce the manifest contract in §4, run the dedup checks in §6, and gate releases on §8. Do not paper over with PDF edits.

---

## 11. Cross-references

- Build pipeline implementation: `src/pipeline.rs`
- Lua filter: `filters/force-fullwidth-hero.lua` (in the rendering repo)
- LaTeX template: `templates/chapter.template.tex` (in the rendering repo)
- Parent repo lineage: `gHashTag/trios` (Rust TRIOS MCP / trios-phd)
- MCP tool exposing this pipeline: `build_pdf` (see README)

When in doubt, prefer the rules in this file over local conventions.
