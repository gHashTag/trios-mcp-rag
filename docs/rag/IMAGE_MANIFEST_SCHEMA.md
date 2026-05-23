# TRIOS PhD Image Manifest Schema

<!-- TRIOS_PHD_IMAGE_PLACEMENT -->
<!-- TRIOS_PHD_IMAGE_DEDUP -->

Reference schema for the SSOT image manifest used by the TRIOS PhD / brochure pipeline. This is the contract that [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) §4 references.

The actual table lives in the Railway/Postgres SSOT alongside `ssot_brochure.chapters`. This file documents the shape; do not run DDL against production from this repo.

## Suggested table

```sql
-- Documentation only. Apply via the trios / trios-phd ingest pipeline,
-- not directly from this MCP-RAG repo.
CREATE TABLE ssot_brochure.images (
    image_id              TEXT PRIMARY KEY,
    role                  TEXT NOT NULL CHECK (role IN (
                              'title',
                              'cover',
                              'part_opener',
                              'chapter_hero',
                              'evidence_figure',
                              'local_diagram',
                              'logo',
                              'watermark',
                              'reference_plate'
                          )),
    canonical_anchor      TEXT NOT NULL,
    section_id            TEXT NOT NULL,
    priority              INT  NOT NULL DEFAULT 100,
    caption               TEXT NOT NULL,
    source                TEXT NOT NULL,
    file_hash             TEXT NOT NULL,
    allowed_repeat_policy TEXT NOT NULL DEFAULT 'none' CHECK (
                              allowed_repeat_policy IN (
                                  'none',
                                  'every_part_opener',
                                  'every_chapter_opener',
                                  'title_page_only',
                                  'watermark',
                                  'reference_plate'
                              )
                          )
);

CREATE UNIQUE INDEX images_unique_anchor_priority
    ON ssot_brochure.images (canonical_anchor, role, priority);

CREATE INDEX images_by_hash ON ssot_brochure.images (file_hash);
```

## Example rows

```sql
-- title hero (only on the title page)
INSERT INTO ssot_brochure.images VALUES (
    'hero-trios-s3ai-engraving-01',
    'title',
    'frontmatter-title',
    'frontmatter-title',
    10,
    'TRIOS S3AI title plate (engraved).',
    'assets/heroes/trios-s3ai-engraving-01.pdf',
    'sha256:<hash>',
    'title_page_only'
);

-- part opener
INSERT INTO ssot_brochure.images VALUES (
    'part-i-opener-symmetry-plate',
    'part_opener',
    'part-i-opener',
    'part-i-opener',
    10,
    'Part I — Symmetry. Engraved opener plate.',
    'assets/parts/part-i-opener.pdf',
    'sha256:<hash>',
    'none'
);

-- chapter hero
INSERT INTO ssot_brochure.images VALUES (
    'ch-03-hero-symmetry-axes',
    'chapter_hero',
    'ch-03-symmetry',
    'ch-03-symmetry',
    10,
    'Chapter 3 hero: symmetry axes of the S3AI construction.',
    'assets/chapters/ch-03-hero.pdf',
    'sha256:<hash>',
    'none'
);

-- evidence figure (placed after its first textual reference inside ch-03)
INSERT INTO ssot_brochure.images VALUES (
    'ch-03-fig-rotation-group',
    'evidence_figure',
    'ch-03-symmetry#rotation-group',
    'ch-03-symmetry',
    20,
    'Figure 3.2 — Rotation group representation.',
    'assets/figures/ch-03-rotation-group.pdf',
    'sha256:<hash>',
    'none'
);
```

## Field-by-field notes

- **`image_id`** — stable kebab-case. Never rename; if the visual is replaced, mint a new id and retire the old one.
- **`role`** — drives sizing and placement. The Lua filter (`force-fullwidth-hero.lua`) should look at this, not at filename heuristics.
- **`canonical_anchor`** — chapter slug, sub-section slug, or claim id. MUST exist in the rendered Markdown; otherwise the loader drops the image and emits a warning.
- **`section_id`** — the section the renderer actually attaches the image to. For hero / part_opener / chapter_hero this equals `canonical_anchor`. For evidence figures it may be a sub-section.
- **`priority`** — lower wins. Use multiples of 10 so future inserts don't require reflowing.
- **`caption`** — required non-empty for any role that renders inline (`evidence_figure`, `local_diagram`). Watermark / logo may use a short label.
- **`source` / `path`** — repo-relative; must resolve at build time.
- **`file_hash`** — sha256 of the asset bytes. The dedup checks in `IMAGE_PLACEMENT.md` §6 use this.
- **`allowed_repeat_policy`** — defaults to `none`. Anything else MUST be justified by `role`.

## Validation checklist (loader-side)

A loader implementing this manifest MUST refuse, or warn-and-skip, any row that:

- Has a duplicate `image_id`.
- Has a `canonical_anchor` that does not resolve to an existing chapter / section.
- Has empty `caption` for `evidence_figure` / `local_diagram`.
- Has `allowed_repeat_policy != 'none'` for a role that does not permit repetition.
- Has a `file_hash` collision with a different `image_id` (warn, do not error).

See [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) §5–§6 for the placement and dedup rules that consume these fields.
