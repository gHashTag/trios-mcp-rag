#!/usr/bin/env python3
"""
Strip TSV-row leaks from `ssot_brochure.chapters.body_md`.

Three chapters (london-handout, p1-14-conclusion, p3-13-phd-integration)
have a contamination pattern where each line that looks like a TSV row
from the chapters table itself was concatenated into body_md. Each leak
line has the structure:

    <slug>\t<kind>\t<order_key>\t<title>\t<format>\t<wc>\t<sha256>\t<file>\t[<illustration>]\t# Heading...

We need to keep the `# Heading...` part (it is a valid chapter heading
that the surrounding text refers to) and drop everything in front of
it on that line.

Strategy: for any line containing a TAB and matching the
    ^[a-z][a-z0-9-]+\\t(paper[1-3]|frontmatter|hardware_addendum|
                        appendix|handout|unified)\\t
pattern, drop everything up to and including the substring matching
    \\t# (so the `# Heading` survives). Also drop any line that is the
TSV continuation of metadata fields without a heading at all (where the
line does not contain '\\t#').

The script writes UPDATE statements to stdout (dry-run by default).
Pass `--apply` to execute against $DATABASE_URL.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from typing import Iterable

import psycopg2  # type: ignore

LEAK_RE = re.compile(
    r"^[A-Za-z][A-Za-z0-9_-]+\t"
    r"(?:paper[1-3]|frontmatter|hardware_addendum|appendix|handout|unified)"
    r"\t",
)

HEADING_AFTER_TABS = re.compile(r"\t(#\s+.+)$")


def clean_body(body: str) -> tuple[str, int]:
    """Return (cleaned_body, num_lines_modified_or_dropped)."""
    out: list[str] = []
    changed = 0
    for line in body.splitlines():
        if LEAK_RE.match(line):
            # Try to recover a trailing "# Heading" if present.
            m = HEADING_AFTER_TABS.search(line)
            if m:
                out.append(m.group(1))
                changed += 1
            else:
                # Pure metadata row, drop entirely.
                changed += 1
        else:
            out.append(line)
    return "\n".join(out), changed


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true",
                    help="Execute UPDATEs instead of dry-run.")
    ap.add_argument("--slug", action="append", default=None,
                    help="Limit to these slugs (repeatable).")
    args = ap.parse_args(argv[1:])

    dsn = os.environ.get("DATABASE_URL")
    if not dsn:
        print("DATABASE_URL not set", file=sys.stderr)
        return 2

    conn = psycopg2.connect(dsn)
    conn.autocommit = False
    cur = conn.cursor()

    if args.slug:
        cur.execute(
            "SELECT slug, body_md FROM ssot_brochure.chapters "
            "WHERE slug = ANY(%s) ORDER BY slug",
            (args.slug,),
        )
    else:
        cur.execute(
            "SELECT slug, body_md FROM ssot_brochure.chapters "
            "WHERE body_md LIKE '%vasilev_pellis_constants_trinity_s3ai_dna%' "
            "ORDER BY slug"
        )
    rows = cur.fetchall()

    total_lines_fixed = 0
    n_updates = 0
    for slug, body in rows:
        cleaned, changed = clean_body(body)
        if cleaned == body:
            print(f"  {slug}: no change", file=sys.stderr)
            continue
        n_updates += 1
        total_lines_fixed += changed
        before = len(body)
        after = len(cleaned)
        print(
            f"  {slug}: {changed} lines changed, "
            f"body shrank {before} -> {after} chars",
            file=sys.stderr,
        )
        if args.apply:
            cur.execute(
                "UPDATE ssot_brochure.chapters "
                "SET body_md = %s WHERE slug = %s",
                (cleaned, slug),
            )

    if args.apply:
        conn.commit()
        print(f"COMMITTED: {n_updates} chapters updated, "
              f"{total_lines_fixed} leak lines neutralised",
              file=sys.stderr)
    else:
        conn.rollback()
        print(f"DRY RUN: would update {n_updates} chapters, "
              f"{total_lines_fixed} leak lines",
              file=sys.stderr)
    cur.close()
    conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
