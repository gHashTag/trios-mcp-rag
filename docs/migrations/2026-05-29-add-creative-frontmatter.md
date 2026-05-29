# Migration: add creative frontmatter (2026-05-29)

## Scope

Insert 5 new rows into `ssot_brochure.chapters` to provide a
creative opening for the GOLDEN CHAIN brochure (Epigraph, Dedication,
Letter from the Authors, How to Read This Book, GOLDEN CHAIN at a
Glance). All five use `kind = 'frontmatter'` and `order_key` values
that fit between the cover (1) and the attribution page (20).

## Pre-flight (required)

1. Verify the source SQL in `scripts/migrations/2026-05-29-add-creative-frontmatter.sql`.
2. Confirm with the maintainer in the same session before applying
   to Railway. SSOT writes default to read-only.
3. Take a fresh backup of the `frontmatter` rows:

   ```bash
   psql "$DATABASE_URL" -At -F $'\t' -c \
     "COPY (SELECT slug, kind, order_key, title, body_md, COALESCE(illustration_url,'')
            FROM ssot_brochure.chapters WHERE kind='frontmatter' ORDER BY order_key) TO STDOUT" \
     > frontmatter_pre_creative_$(date -u +%Y%m%dT%H%M%SZ).tsv
   ```

## Dry-run

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "BEGIN; \i scripts/migrations/2026-05-29-add-creative-frontmatter.sql ROLLBACK;"
```

## Apply

```bash
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/migrations/2026-05-29-add-creative-frontmatter.sql
```

## Verify

```sql
SELECT slug, order_key, title, length(body_md) AS len
FROM ssot_brochure.chapters
WHERE kind='frontmatter'
ORDER BY order_key;
-- Expect 19 rows; the 5 new slugs at order_key 5, 8, 12, 15, 18.
```

Then rebuild the PDF and verify 252 pages.

## Rollback

```sql
DELETE FROM ssot_brochure.chapters
WHERE slug IN (
  'fm-01a-epigraph', 'fm-01b-dedication', 'fm-01c-prologue',
  'fm-01d-reading-paths', 'fm-01e-at-a-glance'
);
```
