# Migration 2026-05-29 — Clean TSV-row leak in `ssot_brochure.chapters`

## Problem

Three rows in `ssot_brochure.chapters` had a contamination pattern where
TSV-formatted dumps of the chapters table itself were concatenated into
`body_md`. Each leak line had the structure

```
<slug>\t<kind>\t<order_key>\t<title>\t<format>\t<wc>\t<sha256>\t<source>\t[<illustration>]\t# Heading...
```

producing visible artefacts in the brochure PDF:

  * 30+ occurrences of the literal string
    `vasilev_pellis_constants_trinity_s3ai_dna_full_unified_v22_12_canonical.pdf`
  * stray `markdown` tokens
  * 17 SHA-256 hex blobs leaking as raw text

Affected slugs:

  * `london-handout`              (8 leak lines, -1949 chars)
  * `p1-14-conclusion`            (4 leak lines, -1068 chars)
  * `p3-13-phd-integration`       (5 leak lines, -1247 chars)

## Detection

```bash
psql "$DATABASE_URL" -c "
SELECT slug, length(body_md) FROM ssot_brochure.chapters
 WHERE body_md LIKE '%vasilev_pellis_constants_trinity_s3ai_dna%'
 ORDER BY slug;"
```

## Fix

See `scripts/clean_tsv_leak.py`. The cleaner:

  1. Splits `body_md` into lines.
  2. For each line matching the leak regex (`^[A-Za-z][A-Za-z0-9_-]+\t(kind)\t…`):
     - if the line contains a trailing `\t# Heading…`, keep only that
       heading;
     - otherwise drop the line entirely.
  3. Reassembles the body with `\n`.

## Procedure on Railway (required permission: explicit user "go ahead")

```bash
# 1. Backup affected rows.
psql "$RAILWAY_SSOT_URL" -c "
COPY (SELECT * FROM ssot_brochure.chapters
       WHERE body_md LIKE '%vasilev_pellis_constants_trinity_s3ai_dna%')
TO STDOUT" \
  > backups/leaked_chapters_$(date -u +%Y%m%dT%H%M%SZ).tsv

# 2. Dry-run (default).
DATABASE_URL="$RAILWAY_SSOT_URL" python3 scripts/clean_tsv_leak.py

# 3. Apply only after the dry-run output matches expectations.
DATABASE_URL="$RAILWAY_SSOT_URL" python3 scripts/clean_tsv_leak.py --apply
```

## Rollback

```bash
# Re-load the saved TSV via COPY FROM, or run targeted UPDATEs from the backup.
psql "$RAILWAY_SSOT_URL" <<SQL
BEGIN;
DELETE FROM ssot_brochure.chapters
 WHERE slug IN ('london-handout','p1-14-conclusion','p3-13-phd-integration');
\copy ssot_brochure.chapters FROM 'backups/leaked_chapters_TS.tsv';
COMMIT;
SQL
```

## Verification

```bash
DATABASE_URL="$RAILWAY_SSOT_URL" psql -c "
SELECT slug FROM ssot_brochure.chapters
 WHERE body_md LIKE '%vasilev_pellis_constants_trinity_s3ai_dna%';"
# expect: 0 rows
```
