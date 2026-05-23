# TRIOS PhD Pipeline — End-to-End Verification Checklist

<!-- RAG anchors (grep-friendly, do not remove): -->
<!-- TRIOS_PHD_CANONICAL_PIPELINE -->
<!-- TRIOS_PHD_RENDERER_FIRST -->
<!-- TRIOS_PHD_NO_GENERIC_PDF -->
<!-- TRIOS_PHD_SECRET_SAFETY -->
<!-- TRIOS_PHD_STYLE_LOCK -->

This is the **operational, copy-pasteable checklist** for verifying a
full Markdown → pandoc → LaTeX → tectonic → PDF build of the GOLDEN
BRIDGE brochure through `trios-mcp-rag`.

It complements but does not replace:

- [`CANONICAL_PIPELINE.md`](./CANONICAL_PIPELINE.md) — the six durable
  RAG anchors.
- [`PDF_QA_CHECKLIST.md`](./PDF_QA_CHECKLIST.md) — image dedup gate.
- [`../qa/brochure-pdf-checklist.md`](../qa/brochure-pdf-checklist.md)
  — operational checklist with the current accepted numeric baseline.

**Default to read-only.** Every step below is read-only against the
SSOT. None of these commands write to Postgres.

---

## 0. Preflight

1. Confirm the canonical render path (`TRIOS_PHD_CANONICAL_PIPELINE`):
   binaries `pandoc` and `tectonic` are on `PATH`; the LaTeX template
   and Lua filter from the parent renderer exist.

   ```bash
   command -v pandoc   || { echo "missing: pandoc"; exit 1; }
   command -v tectonic || { echo "missing: tectonic"; exit 1; }
   ```

   If either is missing, surface that as a blocker
   (`TRIOS_PHD_NO_GENERIC_PDF`) — **do not** fall back to a different
   renderer.

2. Confirm secret hygiene (`TRIOS_PHD_SECRET_SAFETY`): the DSN comes
   from the environment by name only.

   ```bash
   [ -n "${DATABASE_URL:-}" ] || [ -n "${RAILWAY_SSOT_URL:-}" ] \
     || { echo "no DSN env var set; copy .env.example to .env locally"; exit 1; }
   # Never echo the DSN itself.
   ```

3. Dry-run the pipeline to validate paths, table access, and dependency
   reachability without producing a PDF:

   ```bash
   trios-mcp-rag build-pdf --dry-run \
     --chapters-table ssot_brochure.chapters \
     --template templates/chapter.template.tex \
     --lua-filter filters/force-fullwidth-hero.lua \
     --repo-root .
   ```

   Or through MCP:

   ```jsonc
   {"name":"build_pdf","arguments":{"dry_run":true}}
   ```

## 1. Build (Markdown → pandoc → LaTeX → tectonic → PDF)

Full build, no `--limit`:

```bash
trios-mcp-rag build-pdf \
  --chapters-table ssot_brochure.chapters \
  --template templates/chapter.template.tex \
  --lua-filter filters/force-fullwidth-hero.lua \
  --out-dir generated/out \
  --build-dir generated/build
```

Expected outputs:

- `generated/build/main.md` — the SSOT-rendered Markdown
- `generated/build/main.tex` — the pandoc-produced LaTeX
- `generated/out/main.pdf` — the tectonic-typeset PDF

A smoke build with `--limit 3` is useful when iterating on style /
templates; do **not** publish a `--limit` build.

## 2. Structural validation (`qpdf` / `pdfinfo`)

```bash
qpdf --check generated/out/main.pdf
pdfinfo generated/out/main.pdf | head
```

Pass: `qpdf --check` exits 0; `pdfinfo` reports a sensible page count.
Accepted baseline page count (A4): **150**. A material rise that
coincides with a rise in "very short non-empty pages" (§7 below) is the
signature of a hard-`\clearpage` regression — check the
`TRIOS_PHD_NO_IMAGE_TRAIN` enforcement before publishing.

## 3. Text-layer sanity (`pdftotext`)

```bash
pdftotext -layout generated/out/main.pdf - | head -200
```

Pass: cover page reads cleanly (see §6 for the cover-specific check);
body pages contain real prose; no garbled glyphs / tofu boxes.

## 4. Markdown / LaTeX dedup gates

These are the image-dedup gates from [`PDF_QA_CHECKLIST.md`](./PDF_QA_CHECKLIST.md).

```bash
grep -nE '!\[[^]]*\]\([^)]+\)' generated/build/main.md \
  | awk -F'[()]' '{print $2}' | sort | uniq -c | sort -rn | head

grep -oE '\\includegraphics(\[[^]]*\])?\{[^}]+\}' generated/build/main.tex \
  | sort | uniq -c | sort -rn | head
```

Pass: no image path or `\includegraphics{...}` target has count > 1
outside the allowed exceptions (`title_page_only`, `watermark`,
`reference_plate`). A duplicate is a manifest / Markdown defect — fix
the source, not the PDF (`TRIOS_PHD_RENDERER_FIRST`).

## 5. Duplicate-paragraph and duplicate-heading scans

```bash
# Long-paragraph duplicates (>200 chars), accepted baseline 0:
pdftotext -layout generated/out/main.pdf - \
  | awk 'BEGIN{RS=""} length($0) > 200 {print}' \
  | sort | uniq -c | sort -rn | awk '$1 > 1 {print}'

# Numbered-heading duplicates (e.g. two "3.2 …"), accepted baseline 0:
pdftotext generated/out/main.pdf - \
  | grep -E '^[[:space:]]*[0-9]+(\.[0-9]+)+[[:space:]]+\S' \
  | sort | uniq -c | sort -rn | awk '$1 > 1 {print}'
```

Pass: zero hits on both.

## 6. Cover canon check (`COVER_CANON.md`)

The GOLDEN BRIDGE cover is the GPT Image 2 v1 raster, no crop, black
background, gold title, three chips (PHI / EULER / GAMMA), authors
Dmitrii Vasilev · Stergios Pellis · Scott Olsen. Manual checks:

- [ ] Page 1 is full-bleed (no white margin around the cover image).
- [ ] Background reads black across the entire page.
- [ ] Title "GOLDEN BRIDGE" is gold and centred.
- [ ] Formulas / diagrams visible in white, Da Vinci-style hand
      aesthetic.
- [ ] Three chips visible, in order: **PHI**, **EULER**, **GAMMA**.
- [ ] Author line reads exactly: **Dmitrii Vasilev · Stergios Pellis ·
      Scott Olsen**.
- [ ] No page number / header / footer on the cover page.

A first-page `pdfimages` sanity check (cover image is present, not
synthesised from glyphs):

```bash
pdfimages -list -f 1 -l 1 generated/out/main.pdf
```

If the cover has drifted — wrong colour, missing chip, cropped author
line, or a synthetic glyph-only cover instead of the raster — that is a
`TRIOS_PHD_NO_GENERIC_PDF` violation. Fix the SSOT image row / LaTeX
title-page block; never paint over it in a PDF editor.

## 7. Hero-anchoring / image-train scan (`TRIOS_PHD_NO_IMAGE_TRAIN`)

Page-by-page text-density walk:

```bash
pages=$(pdfinfo generated/out/main.pdf | awk '/^Pages:/ {print $2}')
for n in $(seq 1 "$pages"); do
  words=$(pdftotext -f "$n" -l "$n" generated/out/main.pdf - | wc -w)
  printf '%4d %5d\n' "$n" "$words"
done
```

Pass: at most **1** page with <40 words (the title / cover page).
Adjacent low-word pages are an image train — fix the SSOT, not the PDF.

Very short non-empty pages (the hard-`\clearpage`-per-section
regression signal):

```bash
pages=$(pdfinfo generated/out/main.pdf | awk '/^Pages:/ {print $2}')
short=0
for n in $(seq 2 "$pages"); do
  words=$(pdftotext -f "$n" -l "$n" generated/out/main.pdf - | wc -w)
  if [ "$words" -gt 0 ] && [ "$words" -lt 15 ]; then
    short=$((short + 1))
    printf 'short page: %d (%d words)\n' "$n" "$words"
  fi
done
echo "very short non-empty pages: $short"
```

Pass: **0**.

## 8. Secret / stale / math-anomaly scan (`TRIOS_PHD_SECRET_SAFETY`)

Secrets — DSNs, tokens, API keys leaking into the artefact:

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE 'postgres(ql)?://|railway\.app|RAILWAY_|DATABASE_URL=|password=|token=|sk-[A-Za-z0-9]' \
  && echo 'POSSIBLE LEAK — stop and investigate' \
  || echo 'secret scan (PDF): clean'
```

Secrets in the working tree (excluding markdown docs that mention env
var names by design):

```bash
git grep -nE 'postgres(ql)?://[^ ]+:[^ ]+@' -- ':!*.md' \
  || echo 'secret scan (tree): clean'
```

Stale markers:

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE 'TODO|FIXME|XXX|TKTK|LOREM|<<|>>|\[draft\]|\[wip\]|<placeholder>|YYYY|<DATE>' \
  || echo 'stale-marker scan: clean'
```

Math anomalies (orphan TeX leaking into the text layer):

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE '\\frac|\\sum|\\int|\\sqrt|\$\$|\\\\(left|right)\\b' \
  || echo 'math-anomaly scan: clean'
```

Pass: 0 hits across all four. Any secret hit triggers
`TRIOS_PHD_SECRET_SAFETY` rotation: stop, tell the user *where* (not
*what*), recommend rotation, and do not force-push history without
explicit confirmation.

## 9. Cyrillic scan (public English build)

```bash
pdftotext generated/out/main.pdf - | grep -cP '[\x{0400}-\x{04FF}]'
```

Accepted baseline: **0**. Non-zero on a public English build is a flag
— confirm before publishing per the language policy.

## 10. Claim-status sanity (`TRIOS_PHD_CLAIM_STATUS`)

Spot-check that strong empirical / theoretical claims carry an
explicit status (Verified / Empirical fit / Open conjecture /
High-risk / Retracted). Marketing language is a flag:

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE -i 'breakthrough|revolutionary|paradigm-shifting|world-first|nobel|fields medal|prize-winning|definitively|settles the question' \
  || echo 'hype-language scan: clean'
```

Pass: zero hits, or each hit is justified text (e.g. discussing
historical Nobel context, not claiming one).

## 11. Reproducibility log

Record alongside the build:

- commit SHA of `trios-mcp-rag`
- chapters table used (`ssot_brochure.chapters` vs `ssot.chapters`)
- template + Lua-filter paths
- `pandoc --version` and `tectonic --version`
- whether `--limit` was used and to what value
- SSOT row count at build time (from `list_chapters` MCP call)
- which `.env.example`-derived variables were set (by name only, never
  values)

---

## Acceptance summary

A build is accepted when, in order:

1. `pandoc` + `tectonic` were on PATH and produced `main.md`,
   `main.tex`, `main.pdf` through the canonical pipeline.
2. `qpdf --check` is clean, `pdfinfo` shows a sensible page count
   (~150 A4 baseline).
3. Markdown / LaTeX dedup gates have zero duplicates outside allowed
   exceptions.
4. Duplicate-paragraph, duplicate-heading, Cyrillic, short-non-empty,
   image-train, secret, stale-marker, math-anomaly, and hype-language
   scans are all clean (0 hits) or within the documented baseline.
5. Cover canon (§6) checks pass.
6. Reproducibility log (§11) is filled in.

A failing gate is **not** a styling issue. Fix the SSOT / Markdown /
filter / template — never the exported PDF (`TRIOS_PHD_RENDERER_FIRST`).
