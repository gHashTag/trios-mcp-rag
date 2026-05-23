# TRIOS MCP-RAG documentation index

This directory holds the **rules and contracts that future agents (Claude Code, Cursor, Windsurf, opencode, and any MCP-RAG consumer) must read before touching the TRIOS PhD / brochure pipeline.**

These docs are intentionally grep-friendly. Search for the all-caps anchors below.

## Documents

- [`CANONICAL_PIPELINE.md`](./CANONICAL_PIPELINE.md) — durable RAG anchors for the whole pipeline.
  Anchors: `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`, `TRIOS_PHD_STYLE_LOCK`, `TRIOS_PHD_NO_GENERIC_PDF`, `TRIOS_PHD_SECRET_SAFETY`, `TRIOS_PHD_CLAIM_STATUS`.
- [`COVER_CANON.md`](./COVER_CANON.md) — GOLDEN BRIDGE front cover invariants (GPT Image 2 v1, no-crop A4, black background, gold title, three chips PHI/EULER/GAMMA, authors Dmitrii Vasilev · Stergios Pellis · Scott Olsen).
  Anchors: `TRIOS_PHD_STYLE_LOCK`, `TRIOS_PHD_RENDERER_FIRST`, `TRIOS_PHD_NO_GENERIC_PDF`, `TRIOS_PHD_COVER_CANON`, `GOLDEN_BRIDGE_COVER_V1`.
- [`PIPELINE_VERIFICATION.md`](./PIPELINE_VERIFICATION.md) — copy-pasteable end-to-end Markdown → pandoc → LaTeX → tectonic → PDF verification recipe (qpdf, pdfinfo, pdftotext, secret scan, hero-anchoring scan).
  Anchors: `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`, `TRIOS_PHD_NO_GENERIC_PDF`, `TRIOS_PHD_SECRET_SAFETY`, `TRIOS_PHD_STYLE_LOCK`.
- [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) — single source of truth for image placement and deduplication.
  Anchors: `TRIOS_PHD_IMAGE_PLACEMENT`, `TRIOS_PHD_IMAGE_DEDUP`, `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`, `TRIOS_PHD_STYLE_LOCK`.
- [`IMAGE_MANIFEST_SCHEMA.md`](./IMAGE_MANIFEST_SCHEMA.md) — required fields for SSOT image rows that feed the renderer.
  Anchors: `TRIOS_PHD_IMAGE_PLACEMENT`, `TRIOS_PHD_IMAGE_DEDUP`.
- [`PDF_QA_CHECKLIST.md`](./PDF_QA_CHECKLIST.md) — blocking checks to run before sharing or committing a generated PDF.
  Anchors: `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`, `TRIOS_PHD_STYLE_LOCK`, `TRIOS_PHD_IMAGE_DEDUP`.
- [`trios-phd-canon.md`](./trios-phd-canon.md) — canonical brochure invariants and the `TRIOS_PHD_NO_IMAGE_TRAIN` rule.

## How to use this directory

If you are an agent about to:

- Edit a chapter body, the image manifest, or `src/pipeline.rs` → read `IMAGE_PLACEMENT.md` and `IMAGE_MANIFEST_SCHEMA.md` first.
- Generate or share a PDF → run through `PDF_QA_CHECKLIST.md` before declaring the build done.
- "Fix" a PDF that has duplicated or misplaced images → STOP. The fix is in the SSOT / Markdown / filter / template, not in the PDF. See `IMAGE_PLACEMENT.md` §9.

## Why these docs exist

The TRIOS S3AI brochure has shipped with duplicated and misplaced hero images more than once. The root cause has been the same each time: there was no contract between how images are stored in the SSOT and how the renderer decides where to place them. These docs encode that contract so future agents and renderers can produce a correct PDF deterministically — and so reviewers can reject a defective build with a concrete reference.
