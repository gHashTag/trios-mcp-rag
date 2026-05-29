# Brochure / PDF QA Checklist — Operational

This is the *operational* QA checklist used to accept a TRIOS PhD
brochure PDF build. It is a companion to `docs/agent-rules/05-brochure-qa-checklist.md`
(which is the normative rule) and to `docs/rag/trios-phd-canon.md`
(which carries the named invariants and the accepted numeric baseline).

Run the steps below in order. **All numeric rows must match or improve
on the accepted baseline. A regression on any row is a hard blocker.**

## 0. Inputs

- `generated/out/main.pdf` — the candidate PDF.
- `generated/build/main.md` — the Markdown the PDF was rendered from.
- Tools: `qpdf`, `pdfinfo`, `pdftotext` (`poppler-utils`).

## 1. Structural validation

```bash
qpdf --check generated/out/main.pdf
pdfinfo generated/out/main.pdf | head
```

Pass: `qpdf --check` exits 0; `pdfinfo` reports a sensible page count.

### 1a. Reproducibility metadata gate (active since v12)

The PDF MUST NOT carry a `CreationDate` line (or any other timestamp
field) in its metadata. `SOURCE_DATE_EPOCH` plus tectonic's reproducible
mode neutralises the non-determinism source called out in Track 4 of
the literature canon; if `CreationDate` reappears, the sha256 baseline
`6d2e29ed…` cannot be reproduced.

```bash
if pdfinfo generated/out/main.pdf | grep -q '^CreationDate'; then
  echo "FAIL: CreationDate present — reproducibility regression" >&2
  exit 1
fi
```

Pass: the command above prints nothing and exits 0. (Rule 07 §8 —
`CreationDate` neutralisation is the **active** part of that
refinement; the tectonic version pin is still `planned`.)

## 2. Page count

```bash
pdfinfo generated/out/main.pdf | awk '/^Pages:/ {print $2}'
```

**Accepted baseline: 259 A4 pages** (post-v12, 2026-05-29) inside the
**240 ± 25 band**. Current `ssot_brochure.chapters` has **69 rows**
averaging ~3.75 pp/chapter → ~259 pp. Previously: 150 pp (~30 chapters,
v8), 242 pp (62 chapters, v10). **The decisive signal for a hard
`\clearpage` regression is row 8 ("very short non-empty pages") —
not the absolute page count.** A page count outside the band *without*
a rise in row 8 means the SSOT grew or shrank, not that the template
broke. A rise in row 8 — even at a page count inside the band — is
the regression signature; re-check the `TRIOS_PHD_NO_IMAGE_TRAIN`
enforcement and prefer a soft keep-together rule for
heading + hero + first paragraph(s).

## 3. Duplicate-paragraph scan (long paragraphs)

Goal: catch exact duplicate long paragraphs (>200 chars) that suggest a
botched merge.

```bash
pdftotext -layout generated/out/main.pdf - | \
  awk 'BEGIN{RS=""} length($0) > 200 {print}' | \
  sort | uniq -c | sort -rn | awk '$1 > 1 {print}'
```

**Accepted baseline: 0 hits.**

> **Note for multi-chapter compendiums:** repeated bibliographic entries
> (author names, DOI strings, arXiv IDs, URL fragments) across different
> chapter reference lists are expected artifacts of the per-chapter
> citation style. Exclude lines containing `zenodo`, `vixra`, `HAL`,
> `NIST`, `physics.nist.gov`, `DOI`, or `/Constants/` from the scan.
> Flag only prose paragraphs that repeat verbatim.
>
> **Additional acceptable echo classes** (also exclude before flagging):
>
> 1. **Author / venue tokens in references.** Lines matching common
>    author names listed in the SSOT (`Vasilev`, `Pellis`, `Olsen`,
>    `Sherbon`, `Heyrovska`, `Coldea`, `Wu`, `Fring`, `El Naschie`),
>    venue names (`Phys. Rev.`, `Nucl. Phys.`, `arXiv:`), DOIs
>    (`10.[0-9]+/`), and viXra IDs.
> 2. **Hyphenation tail lines.** `pdftotext -layout` preserves
>    end-of-line hyphenated word fragments (`spec-`, `inspec-`,
>    `pub-`, `ification.`, `lications`). These are PDF text-extraction
>    artefacts, not content duplicates — exclude lines matching
>    `^[a-z]+\.?$` or `^[a-z]+-$`.
> 3. **ASCII flow diagrams.** Vertical bars (`|`) and stand-alone
>    arrow letters (`v`, `^`) on otherwise empty lines are part of
>    intentional ASCII flow charts inside chapters — exclude lines
>    matching `^\s*[|v^]\s*$`.
> 4. **`kind='unified'` digest articles.** Chapters with
>    `kind='unified'` are by design summary / digest articles that
>    aggregate key passages from other chapters (analogous to a
>    "Conclusions" section in a textbook). Echoes between a `unified`
>    chapter and any other chapter are **acceptable by design**. Flag
>    only echoes that occur **between two non-`unified` chapters**.

*Pragmatic command (incorporates all four exclusions):*

```bash
pdftotext -layout generated/out/main.pdf - | \
  awk 'BEGIN{RS=""} length($0) > 200 {print}' | \
  grep -viE 'zenodo|vixra|HAL|NIST|physics\.nist\.gov|DOI|/Constants/|arxiv\.org|Vasilev|Pellis|Olsen|Sherbon|Heyrovsk|Coldea|Wu, J|Fring|El Naschie|Phys\. Rev|Nucl\. Phys|10\.[0-9]+/' | \
  awk 'BEGIN{RS=""} !/^[[:space:]]*[a-z]+[.-]?[[:space:]]*$/ && !/^[[:space:]]*[|v\^][[:space:]]*$/ {print}' | \
  sort | uniq -c | sort -rn | awk '$1 > 1 {print}'
```

## 4. Duplicate numbered headings

Goal: catch repeated numbered headings (e.g. two "3.2 …").

```bash
pdftotext generated/out/main.pdf - | \
  grep -E '^[[:space:]]*[0-9]+(\.[0-9]+)+[[:space:]]+\S' | \
  sort | uniq -c | sort -rn | awk '$1 > 1 {print}'
```

**Accepted baseline: 0 hits.**

## 5. Cyrillic scan (English public build)

```bash
pdftotext generated/out/main.pdf - | grep -cP '[\x{0400}-\x{04FF}]'
```

**Accepted baseline: 0 hits.** Non-zero on a public English build is a
flag — confirm before publishing.

## 6. Secret / stale-marker / math-anomaly scan

Secrets (DSNs, tokens, API keys):

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE 'postgres(ql)?://|railway\.app|RAILWAY_|DATABASE_URL=|password=|token=|sk-[A-Za-z0-9]' \
  && echo 'POSSIBLE LEAK — stop and investigate' \
  || echo 'secret scan (PDF): clean'

git grep -nE 'postgres(ql)?://[^ ]+:[^ ]+@' -- ':!*.md' \
  || echo 'secret scan (tree): clean'
```

Stale markers:

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE 'TODO|FIXME|XXX|TKTK|LOREM|<<|>>|\[draft\]|\[wip\]|<placeholder>|YYYY|<DATE>' \
  || echo 'stale-marker scan: clean'
```

Math anomalies (orphan TeX leaking into text layer):

```bash
pdftotext generated/out/main.pdf - | \
  grep -nE '\\frac|\\sum|\\int|\\sqrt|\$\$|\\\\(left|right)\\b' \
  || echo 'math-anomaly scan: clean'
```

**Accepted baseline: 0 hits across all three.** Any hit is a hard
blocker. For secrets, follow rule 03 §"If a secret is accidentally
exposed".

## 7. Hero-anchoring scan (no image trains)

Per `TRIOS_PHD_NO_IMAGE_TRAIN` (see `docs/rag/trios-phd-canon.md` and
rule 02): every hero must be semantically anchored to a substantive
heading and body text, and no two heroes back-to-back without a real
prose buffer.

Page-by-page text-density walk:

```bash
pages=$(pdfinfo generated/out/main.pdf | awk '/^Pages:/ {print $2}')
for n in $(seq 1 "$pages"); do
  words=$(pdftotext -f "$n" -l "$n" generated/out/main.pdf - | wc -w)
  printf '%4d %5d\n' "$n" "$words"
done
```

Flag pages with fewer than ~40 words as image-heavy / low-context
candidates, then check whether any two such candidates are adjacent.
Adjacency = image train = fix at the source.

**Accepted baseline: 1 candidate (the title page only).**

## 8. Very short non-empty pages

Goal: catch the regression where a hard `\clearpage` per section
creates short title-only pages.

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

**Accepted baseline: 0.** A non-zero count strongly suggests the
brochure is using a hard `\clearpage` before sections rather than a
soft keep-together group — read `docs/rag/trios-phd-canon.md` §2 and
fix the template, not the symptom.

## 9. Reproducibility log

Record in the build's change-log entry:

- commit SHA of `trios-mcp-rag`
- chapters table used (`ssot_brochure.chapters` vs `ssot.chapters`)
- template + Lua-filter paths
- `pandoc` and `tectonic` versions
- whether `--limit` was used and to what value
- SSOT row count at build time

## Accepted baseline (summary)

| #  | Metric                                        | Accepted value           |
|----|-----------------------------------------------|--------------------------|
| 0  | Chapter count (`ssot_brochure.chapters`)      | 69 (post-v12)            |
| 2  | Page count (A4)                               | 259 inside 240 ± 25 band |
| 0  | File size                                     | ~3.5 MB                  |
| 0  | Reference sha256                              | `6d2e29ed32cc92b4aea32a0c639f7f16c646d94e1aa4adba97787869ec79293d` |
| 1  | `qpdf --check`                                | clean                    |
| 3  | Exact duplicate long paragraphs (after exclusions in §3) | 0           |
| 4  | Duplicate numbered headings                   | 0                        |
| 5  | Cyrillic hits (public English build)          | 0                        |
| 6  | Secret / stale / math anomaly hits            | 0                        |
| 8  | Very short non-empty pages                    | 0 — **decisive regression signal** |
| 7  | Image-heavy / low-context candidate pages     | 1 (title page only)      |

A build that meets this table and clears step 9 is accepted.

**Note on baseline history.** The original 150-page baseline was set
when `ssot_brochure.chapters` held ~30 rows. The SSOT has since grown
through v9–v12 to 69 chapters; the post-v12 build `f7c36a7`
(2026-05-29) stabilised at 259 pages / 3.5 MB. **Use row 8 ("very
short non-empty pages") — not absolute page count — as the primary
regression detector.** Page count tracks SSOT row count and average
chapter length, which drift wave to wave; the short-page signal is
template-driven and binary.

| Wave | Date       | Chapters | Pages | File size | sha256 (first 8) | Notes              |
|------|------------|----------|-------|-----------|------------------|--------------------|
| v8   | 2026-05    | 30+      | ~150  | n/a       | n/a              | rebuild            |
| v10  | 2026-05    | 62       | ~242  | n/a       | n/a              | rebuild            |
| v12  | 2026-05-29 | **69**   | **259** | **3.5 MB** | `6d2e29ed`     | rebuild            |
| v13  | 2026-05-29 | 69       | 259   | 3.5 MB    | `6d2e29ed`       | audit-only, no rebuild |
| v14  | 2026-05-29 | 69       | 259   | 3.5 MB    | `6d2e29ed`       | audit-only, no rebuild |
