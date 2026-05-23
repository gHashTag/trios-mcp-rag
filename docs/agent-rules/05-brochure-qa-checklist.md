# 05 — Brochure / PDF QA Checklist

Run this checklist before declaring a brochure, article, or PDF build
complete. None of the steps require live Postgres — they operate on
the generated artefacts. Several require `qpdf`, `pdfinfo`, and
`pdftotext` (from the `poppler-utils` package).

## 1. Duplicate-section scan

Goal: catch chapters or sections that ended up repeated, often from a
botched merge or a re-run that appended instead of replacing.

- Extract text: `pdftotext generated/out/main.pdf - | less`
- Look for repeated chapter titles. A simple heuristic:
  - `pdftotext generated/out/main.pdf - | grep -E "^(Chapter|Глава) " | sort | uniq -c | sort -rn | head`
- For Markdown: `awk '/^# /{print}' generated/build/main.md | sort | uniq -c | sort -rn | head`
- Any count > 1 needs an explicit reason (e.g. "Preface" appearing
  twice is wrong; "Appendix A.1" appearing twice is wrong).

## 2. Stale-marker scan

Goal: catch leftover scaffolding from drafting.

Scan the generated Markdown and PDF text for:

- `TODO`, `FIXME`, `XXX`, `TKTK`, `LOREM`, `Lorem ipsum`
- `<<`, `>>` (commonly used as placeholder brackets)
- `[draft]`, `[wip]`, `[fill in]`, `<placeholder>`
- date/year placeholders like `YYYY`, `MM/DD`, `<DATE>`
- `Untitled`, `Untitled chapter`, `New chapter`

Command:

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE "TODO|FIXME|XXX|TKTK|LOREM|<<|>>|\\[draft\\]|\\[wip\\]|<placeholder>|YYYY|<DATE>" || \
  echo "stale-marker scan: clean"
```

## 3. Style-drift scan

Goal: catch silent style regressions.

- Cover: still white academic title page? Not teal, not black (unless
  explicitly requested for this build — note that in the changelog).
- Body font: still serif?
- Hero panels: present on chapter openers, full-width, black-and-white
  engraved?
- Margins: still book-standard, not tightened?
- Image sizes: heroes still large, not thumbnails?

Spot-check by opening the PDF and scanning the first three chapter
openers and the title page. If the build pipeline emits a style hash
or template version, log it.

## 4. Hero-anchoring scan (no image trains) — `TRIOS_PHD_NO_IMAGE_TRAIN`

Goal: catch consecutive hero panels rendered without intervening
substantive text — the "image train" / "hero gallery" failure mode.
This is the named invariant **`TRIOS_PHD_NO_IMAGE_TRAIN`** (see
`docs/rag/trios-phd-canon.md` §2).

Per rule 02, every hero panel must be anchored to a nearby substantive
heading and body text. No two heroes back-to-back without a meaningful
text buffer.

Enforcement note: use a **soft keep-together** rule for the
*section heading + hero/context block + first paragraph(s)* group. Do
**not** insert a hard `\clearpage` (or `\newpage`) before every section
— a hard clearpage per section creates short title-only pages whenever
a section starts near the bottom of a page, and shows up in the QA
scan as "very short non-empty pages".

What to look for, page by page:

- Pages that are dominated by a hero with little or no body text and
  whose neighbour page is *also* a hero-dominant page.
- Sequences where a chapter opener hero is immediately followed by a
  near-duplicate "transition" heading that carries its own hero.
- Headings whose body is effectively just the hero block (no
  paragraphs of substantive prose underneath).

Quick triage:

- Use `pdfinfo` for the page count and walk pages with `pdftotext -f N
  -l N generated/out/main.pdf -` to estimate text density per page.
- Flag any page whose extracted text is below a small-prose threshold
  (e.g. fewer than ~40 words) as an image-heavy / low-context
  candidate, then check whether its neighbours are also low-context.
- Two adjacent low-context, hero-dominant pages = image train. Fix at
  the source: keep the hero on the substantive section, drop the
  transition / duplicate hero.

Acceptance: image-heavy / low-context candidate pages should be few
and non-adjacent, and every remaining hero should have substantive
text under it (not just a caption).

Worked example (2026-05 audit): a prior build flagged 6 image-heavy /
low-context candidate pages, several of them adjacent — symptoms of
duplicate "transition" headings that carried hero blocks of their own.
Removing the transition hero blocks and applying a soft keep-together
rule (rather than a hard `\clearpage` per section) reduced the
candidate count to 1 (the title page only) and stabilised the build at
150 A4 pages with `qpdf --check` clean. See
`docs/qa/brochure-pdf-checklist.md` for the accepted numeric baseline.

## 5. Secret scan

Goal: catch DSNs, tokens, or passwords that leaked into the artefact
or into the repo.

```bash
# In generated artefacts
pdftotext generated/out/main.pdf - | \
  grep -nE "postgres(ql)?://|railway\\.app|RAILWAY_|DATABASE_URL=|password=|token=|sk-[A-Za-z0-9]" && \
  echo "POSSIBLE LEAK — stop and investigate" || \
  echo "secret scan (PDF): clean"

# In the working tree
git grep -nE "postgres(ql)?://[^ ]+:[^ ]+@" -- ':!*.md' || echo "secret scan (tree): clean"
```

Any hit is a hard blocker. Stop the publish, follow rule 03 §"If a
secret is accidentally exposed".

## 6. Language scan

Goal: enforce the repo-facing language policy.

Public-facing repo artefacts are English-only at the time of writing
(see rule 06). For the generated brochure / PDF:

```bash
pdftotext generated/out/main.pdf - | \
  grep -cP "[\\x{0400}-\\x{04FF}]" || true
```

A non-zero Cyrillic count in a build intended for the public repo is a
flag, not an automatic failure — confirm with the user before
publishing.

## 7. PDF structural validation

Goal: catch broken PDFs.

```bash
qpdf --check generated/out/main.pdf
pdfinfo generated/out/main.pdf
pdftotext generated/out/main.pdf - | wc -w
```

Expectations:

- `qpdf --check` exits 0, "No syntax or stream encoding errors".
- `pdfinfo` reports a sensible page count (matches `--limit` if used,
  or matches expected chapter count for a full build).
- `pdftotext … | wc -w` is non-zero and roughly matches the SSOT's
  total `word_count` (allow ±10% for front matter, captions, etc).

## 8. Build reproducibility note

Record, in the build's change-log entry:

- the commit SHA of `trios-mcp-rag` used
- the chapters table used (`ssot_brochure.chapters` vs `ssot.chapters`)
- the template / Lua-filter paths
- the `pandoc` and `tectonic` versions
- whether `--limit` was used and to what value
- the SSOT row count at build time

Without these, a future agent cannot tell whether a regression is in
the source, the renderer, or the SSOT.
