# Migration: v6 statements page + URL trailing-punct cleanup (2026-05-29)

## Scope

Two changes to `ssot_brochure.chapters`:

1. **INSERT** `fm-01f-statements` at `order_key=19` — Funding / CoI / Ethics / Data availability / CRediT / ORCID / AI-use page.
2. **UPDATE** all rows whose `body_md` contains a URL with trailing `.,;` punctuation glued to it: strip the trailing punctuation.

## Pre-flight

```bash
# Backup all chapters before touching anything
psql "$DATABASE_URL" -At -F $'\t' -c \
  "COPY (SELECT slug, kind, order_key, title, body_md FROM ssot_brochure.chapters ORDER BY order_key) TO STDOUT" \
  > all_chapters_pre_v6_$(date -u +%Y%m%dT%H%M%SZ).tsv
```

## Dry-run

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;
\i scripts/migrations/2026-05-29-v6-statements-and-url-cleanup.sql
SELECT slug, length(body_md) FROM ssot_brochure.chapters
 WHERE slug = 'fm-01f-statements';
ROLLBACK;
SQL
```

## Apply

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 \
  -f scripts/migrations/2026-05-29-v6-statements-and-url-cleanup.sql
```

## Verify

```sql
-- Expect 1 row at order_key=19
SELECT slug, order_key, title, length(body_md)
 FROM ssot_brochure.chapters WHERE slug='fm-01f-statements';
-- Expect 0 rows
SELECT slug FROM ssot_brochure.chapters
 WHERE body_md ~ 'https?://[A-Za-z0-9._/?&=~%#:+@!*-]+[\.,;]+(\s|$)';
```

## Rollback

```sql
DELETE FROM ssot_brochure.chapters WHERE slug='fm-01f-statements';
-- URL trailing-punct strip is not directly reversible; restore body_md
-- columns from the pre-flight TSV backup if needed.
```
