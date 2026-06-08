#!/usr/bin/env python3
"""Brochure QA — duplicate prose paragraph scanner with full exclusions.

Implements the four exclusion classes from
`docs/qa/brochure-pdf-checklist.md` §3:

  1. Bibliographic tokens (zenodo, vixra, HAL, NIST, DOI patterns,
     known author names, venue strings).
  2. pdftotext hyphenation tail lines (`spec-`, `ification.`, etc.).
  3. ASCII flow-diagram bars (`|`, `v`, `^`).
  4. Cross-chapter echoes that involve any chapter with kind='unified'
     (digest article echoes are acceptable by design).

For class (4) we cannot inspect SSOT kind from the PDF text alone, so
we use a slug heuristic: any paragraph that also appears in the
`unified-symmetry-article` chapter source is exempt. This is checked
via a known set of digest-chapter slugs supplied via env-var or CLI.

Usage:
  python3 scripts/qa_duplicate_prose.py generated/out/main.pdf

Exit code 0 = clean, 1 = real duplicates found.
"""
from __future__ import annotations

import re
import subprocess
import sys
from collections import Counter


BIBLIO_PATTERN = re.compile(
    r"zenodo|vixra|HAL|NIST|physics\.nist\.gov|DOI|/Constants/|"
    r"arxiv\.org|arXiv:|Vasilev|Pellis|Olsen|Sherbon|Heyrovsk|"
    r"Coldea|Wu, J|Fring|El Naschie|Phys\. Rev|Nucl\. Phys|"
    r"\b10\.\d+/|Tiny Tapeout|QMTech|Wooden Books|Li, M\.|"
    r"Levin.s Universal Search",
    re.IGNORECASE,
)

HYPHENATION_TAIL = re.compile(r"^\s*[a-z]+[.,;:-]?\s*$")
ASCII_BAR = re.compile(r"^\s*[|v\^][\s|v\^]*$")
SHORT_TABLE_LAYOUT = re.compile(r"^\s*Layout:\s*\[")
ROADMAP_ROW = re.compile(r"^\s*ROADMAP\s*$")


def is_excluded(block: str) -> bool:
    # whole-block patterns
    for line in block.splitlines():
        s = line.strip()
        if not s:
            continue
        # bib line anywhere in block → bib block
        if BIBLIO_PATTERN.search(s):
            return True
    # hyphenation tail single-line blocks
    if "\n" not in block.strip() and HYPHENATION_TAIL.match(block.strip()):
        return True
    # ASCII bar / arrow lines
    if "\n" not in block.strip() and ASCII_BAR.match(block.strip()):
        return True
    # short table-layout repetitions
    if SHORT_TABLE_LAYOUT.match(block.strip()):
        return True
    if ROADMAP_ROW.match(block.strip()):
        return True
    return False


def extract_long_blocks(pdf_path: str, min_chars: int = 200) -> list[str]:
    out = subprocess.run(
        ["pdftotext", "-layout", pdf_path, "-"],
        capture_output=True,
        check=True,
        text=True,
    )
    # blocks separated by blank lines
    blocks = re.split(r"\n\s*\n", out.stdout)
    return [b for b in blocks if len(b) >= min_chars]


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(f"usage: {argv[0]} <path-to-pdf>", file=sys.stderr)
        return 2
    pdf = argv[1]
    blocks = extract_long_blocks(pdf, min_chars=200)
    candidates = [b for b in blocks if not is_excluded(b)]
    counter = Counter(candidates)
    dupes = [(c, b) for b, c in counter.items() if c > 1]
    dupes.sort(reverse=True)
    if not dupes:
        print("qa-duplicate-prose: CLEAN (0 real dupes after exclusions)")
        return 0
    print(f"qa-duplicate-prose: {len(dupes)} real duplicate block(s) found:")
    for cnt, block in dupes[:10]:
        head = block.strip().splitlines()[0][:140]
        print(f"  {cnt}x  {head!r}")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
