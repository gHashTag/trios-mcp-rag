# GOLDEN BRIDGE Front Cover — Canonical Specification

<!-- RAG anchors (grep-friendly, do not remove): -->
<!-- TRIOS_PHD_STYLE_LOCK -->
<!-- TRIOS_PHD_RENDERER_FIRST -->
<!-- TRIOS_PHD_NO_GENERIC_PDF -->
<!-- TRIOS_PHD_COVER_CANON -->
<!-- GOLDEN_BRIDGE_COVER_V1 -->

This document is the **single source of truth for the GOLDEN BRIDGE
brochure front cover.** It is a stricter override of the general
`TRIOS_PHD_STYLE_LOCK` defaults (`docs/agent-rules/02-pdf-style.md`)
for the cover specifically.

When a chat instruction conflicts with anything below, the rule wins
unless the user explicitly overrides it for **the specific build in the
current session.** "Polish the cover", "make it more modern", or
"clean up the design" are **not** valid overrides — they are vague
aesthetic requests and the canonical cover stays.

---

## 1. Canonical identity

The accepted cover is the **GPT Image 2 fully prompted v1 cover**, A4,
no crop. It is *one* raster asset produced as a whole composition; it
is **not** assembled programmatically at build time from individual
type / glyph layers.

| Field                     | Value                                                              |
|---------------------------|--------------------------------------------------------------------|
| Asset source              | GPT Image 2, fully prompted, v1 (canonical revision)               |
| Format                    | Single raster image, full A4 page, no margin crop                  |
| Background                | Solid black (#000000 baseline; ink-rich black is acceptable)       |
| Title typography          | Gold (`GOLDEN BRIDGE`), serif, large, centred                      |
| Formulas / diagrams       | White, Da Vinci-style hand-engraved aesthetic                      |
| Chip row                  | Three chips — **PHI**, **EULER**, **GAMMA** — in this order        |
| Author line               | **Dmitrii Vasilev · Stergios Pellis · Scott Olsen**                |
| Title rendering           | Baked into the raster — the renderer does not retypeset the title  |
| Crop policy               | **No crop.** Full-bleed A4 with the original aspect preserved.     |
| Substitutes allowed       | None for canonical builds                                          |

The cover image lives in the SSOT image manifest with:

- `role = cover` (or `role = title` if treated as the title page hero,
  per project convention — both are acceptable provided
  `allowed_repeat_policy` is set to `title_page_only`)
- `allowed_repeat_policy = title_page_only`
- `canonical_anchor` = the brochure title page slug
- a unique, stable `image_id` (e.g. `cover-golden-bridge-gpt-image-2-v1`)

See [`IMAGE_PLACEMENT.md` §4–§5](./IMAGE_PLACEMENT.md) for the manifest
contract.

## 2. What "no crop" means

- The image must occupy the **full A4 page**, including bleed area.
  No margin, no padding around the cover image.
- LaTeX template responsibility: the title page environment must place
  the cover image at native page size with `\includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{...}`
  (or equivalent) and **disable** the running header / footer / page
  number on this page.
- The image must **not** be down-scaled, sliced, masked, or framed
  inside a "title card". The brochure cover IS the image.

A cover that has been visibly cropped — losing chips, the author line,
or the engraved corners — is a **defect, not an aesthetic choice**.
Fix the template's title-page block, not the image.

## 3. What must NOT happen (forbidden substitutes)

1. **No programmatic / generic LaTeX-only cover** that re-types the
   title in `\Huge\bfseries{GOLDEN BRIDGE}` on a black `\fill` and adds
   `\textbf{$\varphi$}` / `\textbf{$e$}` / `\textbf{$\gamma$}` chips by
   hand. The canonical cover is a single raster asset; the renderer is
   not allowed to replace it with a synthetic layout.
2. **No author re-ordering.** The line is **Dmitrii Vasilev · Stergios
   Pellis · Scott Olsen** in that order, with that punctuation. Do not
   reorder, do not substitute initials, do not anglicise / cyrillicise.
3. **No chip relabelling.** The three chips are **PHI**, **EULER**,
   **GAMMA** — not "φ / e / γ", not "Golden / Natural / Euler", not
   "Constants". The labels on the canonical cover are baked into the
   raster; agents must not "improve" them.
4. **No corporate / teal / white-academic substitute** for the GOLDEN
   BRIDGE cover. The white-academic title page rule in
   `02-pdf-style.md` is the *general* default for TRIOS PhD-style
   brochures; **GOLDEN BRIDGE specifically uses the black cover with
   gold title described above**, and this is the rule for it.
5. **No additional title-page hero.** The cover IS the title page. Do
   not add a second `chapter_hero` image immediately after.
6. **No PDF post-edit.** Do not crop, re-tint, replace, or "clean up"
   the cover in a PDF editor. Fix the asset or the template.

## 4. Authority and revision

- v1 is the canonical revision **at the time of this document**.
  Future revisions (v2+) require an explicit, in-session decision from
  the maintainer that names the new revision and demonstrates how the
  cover spec table in §1 changes. Until then, v1 holds.
- The SSOT row for the cover image carries the `image_id` and
  `file_hash`. If the file hash changes without a documented revision
  bump, treat it as a defect — the asset has been silently swapped.

## 5. Verification (manual)

Run before sharing a build:

- [ ] PDF page 1 is full-bleed: no white margin around the cover image.
- [ ] Background reads black across the entire page.
- [ ] Title "GOLDEN BRIDGE" is gold and centred.
- [ ] Formulas / diagrams visible in white, in a Da Vinci-style hand
      aesthetic — not stock vector art, not modern flat icons.
- [ ] Three chips visible, in order: **PHI**, **EULER**, **GAMMA**.
- [ ] Author line reads exactly: **Dmitrii Vasilev · Stergios Pellis ·
      Scott Olsen**.
- [ ] No page number, header, or footer on the cover page.
- [ ] Page 2 is the first interior content page (or the academic title
      page, per the rest of the build); it is **not** a duplicate of
      the cover.

If any item fails, the cover has drifted. Apply the renderer-first
order from [`IMAGE_PLACEMENT.md` §9](./IMAGE_PLACEMENT.md): fix the
manifest, then the Markdown, then the Lua filter, then the LaTeX
template — never the exported PDF.

## 6. Related anchors

- `TRIOS_PHD_STYLE_LOCK` — general PDF visual identity.
- `TRIOS_PHD_RENDERER_FIRST` — fix the source, not the PDF.
- `TRIOS_PHD_NO_GENERIC_PDF` — no synthetic / generic-renderer
  substitute, including for the cover.

See also:

- [`CANONICAL_PIPELINE.md`](./CANONICAL_PIPELINE.md) — the six durable
  RAG anchors that govern the whole build.
- [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) — image manifest
  contract.
- [`PIPELINE_VERIFICATION.md`](./PIPELINE_VERIFICATION.md) — end-to-end
  build + verification recipe.
