# SSOT Snapshot — read-only cache for offline agents

This directory holds **TSV snapshots** of `ssot_brochure.chapters`,
exported at the moment a build was tagged. They are committed to the
repository so a new agent can boot a local Postgres mirror **without
Railway access** for read-only operations (audit, dry-run, QA).

## Authority

These snapshots are **NOT the SSOT**. Per project rule 2, the SSOT is
the live `ssot_brochure.chapters` table on Railway. The snapshots here
exist for three reasons only:

1. **Cold-start in an isolated sandbox** where the agent has neither a
   Pipedream PostgreSQL connector nor a `.env` DSN.
2. **Forensic replay** — running an old audit against the SSOT state
   that the audit was originally written against.
3. **Diff base** — `git diff` between two TSVs reveals exactly which
   rows a build changed (independent of the migration SQL).

If a snapshot conflicts with the live Railway table, **the Railway
table wins**. Re-export and overwrite the snapshot; never edit it by
hand.

## File naming

`chapters-post-v<NN>.tsv` — the SSOT immediately after the version
tag was committed. Columns:

```
slug   kind   order_key   title   body_md   illustration_url
```

Format: PostgreSQL `\COPY ... WITH (FORMAT csv, DELIMITER E'\t',
HEADER true)`. Load with the same options.

## Provenance

| File                          | Built from commit                                       | sha256       |
|-------------------------------|---------------------------------------------------------|--------------|
| `chapters-post-v12.tsv`       | `7bec06f` (v12 next-wave critic-proof pass)             | `5636ce75…`  |

## Bootstrap a local Postgres mirror from a snapshot

```bash
export PATH="/usr/lib/postgresql/17/bin:$PATH"

# 1. Boot Postgres 17 on port 5433
mkdir -p /tmp/pgdata
initdb -D /tmp/pgdata -U postgres --auth-local=trust --auth-host=trust
pg_ctl -D /tmp/pgdata -l /tmp/pglog -o "-p 5433" start

# 2. Create database + schema + table
createdb -p 5433 -U postgres railway
psql -p 5433 -U postgres -d railway <<'SQL'
CREATE SCHEMA ssot_brochure;
CREATE TABLE ssot_brochure.chapters (
  slug             text PRIMARY KEY,
  kind             text NOT NULL,
  order_key        int  NOT NULL,
  title            text NOT NULL,
  body_md          text NOT NULL,
  illustration_url text
);
SQL

# 3. Load the snapshot
psql -p 5433 -U postgres -d railway -c "
  \\copy ssot_brochure.chapters(slug,kind,order_key,title,body_md,illustration_url)
    FROM 'docs/agents/ssot-snapshot/chapters-post-v12.tsv'
    WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
"

# 4. Verify
psql -p 5433 -U postgres -d railway -c "SELECT count(*) FROM ssot_brochure.chapters;"
# expected: 69

# 5. Wire DATABASE_URL for the Rust pipeline
export DATABASE_URL="postgresql://postgres@127.0.0.1:5433/railway"
```

## Re-exporting after a new build

The build runbook (`docs/migrations/2026-MM-DD-vNN-runbook.md`) ends
with this step:

```bash
psql "$DATABASE_URL" -c "
  \\COPY (SELECT slug,kind,order_key,title,body_md,illustration_url
         FROM ssot_brochure.chapters ORDER BY slug)
    TO 'docs/agents/ssot-snapshot/chapters-post-v<NN>.tsv'
    WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
"
git add docs/agents/ssot-snapshot/chapters-post-v<NN>.tsv
```

Update the **Provenance** table above with the new commit + sha256
when adding a snapshot.
