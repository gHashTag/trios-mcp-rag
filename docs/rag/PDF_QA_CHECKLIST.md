# TRIOS PhD PDF QA Checklist

<!-- TRIOS_PHD_CANONICAL_PIPELINE -->
<!-- TRIOS_PHD_RENDERER_FIRST -->
<!-- TRIOS_PHD_STYLE_LOCK -->
<!-- TRIOS_PHD_IMAGE_DEDUP -->

Run this checklist BEFORE sharing or committing a generated PDF. The rules below are the gating subset of [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) §8 — anything that fails here is a defect, not a quirk.

## 0. Pipeline sanity

- [ ] PDF was produced by `pandoc` + `tectonic` (no ReportLab, no manual export).
- [ ] Build was driven by `trios-mcp-rag build-pdf` (or the equivalent MCP `build_pdf` call).
- [ ] No secrets / DSNs / tokens appear in any committed file, log, or commit message.

## 1. Markdown dedup scan

```bash
grep -nE '!\[[^]]*\]\([^)]+\)' generated/build/main.md \
  | awk -F'[()]' '{print $2}' | sort | uniq -c | sort -rn | head
```

- [ ] No image path has count > 1, **except** allowed exceptions: `title_page_only`, `watermark`, `reference_plate`.

## 2. LaTeX dedup scan

```bash
grep -oE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' generated/build/main.tex \
  | sort | uniq -c | sort -rn | head
```

- [ ] No `\includegraphics{...}` target has count > 1 outside the allowed-exception list.

## 3. Order check

- [ ] Image order in `generated/build/main.tex` matches manifest order (first-use, then `priority` ascending, then `image_id`).
- [ ] No `evidence_figure` precedes its first textual reference in the same chapter.
- [ ] No `chapter_hero` appears after an `evidence_figure` in the same chapter.

## 4. PDF audit (when tools available)

```bash
pdfimages -list generated/out/main.pdf \
  | awk 'NR>2 {print $1, $2, $3, $4}' | sort | uniq -c

pdftotext -layout generated/out/main.pdf - | head -200
```

- [ ] No identical image object on adjacent pages (outside watermark / title exceptions).
- [ ] Title-page text contents match the expected style lock.

## 5. Visual / style lock inspection

- [ ] Page 1: white academic background, serif title, large engraved B&W S3AI hero panel.
- [ ] Standard book margins (no teal banner, no black cover, no corporate template).
- [ ] First 3–5 body pages: chapter hero is the chapter's declared `chapter_hero`, not a bleed-forward from the previous chapter.
- [ ] All images render at the size their `role` dictates (full text-width for heroes, in-line for evidence figures and local diagrams).

## 6. If anything fails

Do NOT edit the PDF. Apply the failure-mode order from [`IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) §9:

1. Fix the SSOT image manifest.
2. Fix the chapter Markdown.
3. Fix the Lua filter.
4. Fix the LaTeX template.
5. Fix the build config in `src/pipeline.rs`.

Then rebuild and rerun this checklist from the top.
