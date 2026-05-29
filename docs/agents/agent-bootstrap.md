# Agent Bootstrap — TRIOS RAG & GOLDEN CHAIN Pipeline

This document is the **single entry point** for any AI agent (Perplexity
Computer, Claude Code, Codex, or other) starting fresh on the TRIOS
project. Read this file end-to-end before issuing any other command.

Companion docs: `docs/audits/` (per-build forensic audits),
`docs/migrations/` (per-build SQL + runbooks), `AGENTS.md`,
`CLAUDE.md`, and `docs/agent-rules/`.

## 1. Skill Discipline (Read First)

Three normative skills cover this project. Load them at the top of every
new session — they carry hard rules (read-only SSOT default, DSN secrecy,
claim-status framing, English-only public artefacts, pandoc + tectonic
pipeline lock-in).

| Skill                  | Scope | What it carries                                                                                       |
|------------------------|-------|-------------------------------------------------------------------------------------------------------|
| `trios-mcp-rag`        | user  | Normative rules for the GOLDEN CHAIN PDF pipeline + SSOT discipline.                                  |
| `trios-research-canon` | user  | Literature backing for those rules — Track 1–4 references with DOIs.                                  |
| `trios-mcp`            | user  | Operating rules for the typed MCP wrapper around `tri` / `trios-igla` (claim-status, R5 fidelity).    |

On Perplexity Computer, these are saved as **user-scope skills** — they
auto-load in any new session under the same account. On Claude Code,
they are also distributed as `.zip` skill bundles shared in chat (look
for `*-skill.zip`).

## 2. Repository Map

Three repositories, three roles. Treat their relationship as
*SSOT → derived → published*.

```
gHashTag/trios-mcp-rag           SSOT-aware build pipeline (Rust)
  ├─ src/pipeline.rs               Postgres → markdown → pandoc → tectonic
  ├─ src/build_pdf.rs              MCP tool wrapper
  ├─ templates/chapter.template.tex
  ├─ filters/*.lua                 Pandoc Lua filters
  ├─ docs/audits/build-*.md        Forensic audit per build
  ├─ docs/migrations/*.sql         Per-build SSOT migrations + verification DO block
  └─ docs/migrations/*-runbook.md  Dry-run / apply / rollback procedure

gHashTag/trios-mcp               Typed MCP wrapper for tri / trios-igla CLIs
  └─ src/                          Byte-for-byte CLI forwarding (R5)

gHashTag/trinity-s3ai             Public showcase + cross-repo ledger
  ├─ README.md                     Live status, latest PDF preview
  ├─ WAVE22_STATUS.md              Cross-repo brochure wave ledger
  ├─ releases/GOLDEN_CHAIN_compendium_vNN.pdf
  ├─ figures/golden_chain_compendium_cover.png
  └─ scripts/refresh_compendium.sh Auto-patches README on new PDF release
```

All three are public on github.com under `gHashTag/*`. The
`trios-mcp-rag` working branch is `docs/agent-wake-up`. PDF baseline
is the **post-v12 build** `7bec06f` (sha256 `6d2e29ed…`); v13 and v14
were docs-only audit waves that did not change the PDF artefact —
see `docs/audits/build-2026-05-29-v13.md` and
`docs/audits/build-2026-05-29-v14.md`.

### Clone (read-only)

```bash
mkdir -p /home/user/workspace
cd /home/user/workspace
git clone --depth=1 -b docs/agent-wake-up \
  https://github.com/gHashTag/trios-mcp-rag.git trios-mcp-rag-repo
git clone --depth=1 https://github.com/gHashTag/trios-mcp.git
git clone --depth=1 https://github.com/gHashTag/trinity-s3ai.git /tmp/trinity-s3ai
```

For write access (pushing commits) use `api_credentials=["github"]` on
the `bash` call — the GitHub connector handles auth without exposing a
PAT in the workspace.

## 3. Postgres SSOT — Three Connection Paths

The SSOT for every chapter, status badge, image reference, and ordering
key is the table `ssot_brochure.chapters` on Railway. By rule 2, files
in the repo are **render targets, not authority**. Every build starts
with a read from this table.

Schema (after v12 — 69 rows):

```
ssot_brochure.chapters
  slug              text PRIMARY KEY
  kind              text          chapter | article | paper | audit | handout | unified | provenance | cover | outreach | front_matter
  order_key         int           Stable ordering (10-step gaps; ranges per kind below)
  title             text
  body_md           text          Markdown source for pandoc
  illustration_url  text NULL     Hero / context image URL (NULL on all rows until B17 lands)
```

`order_key` ranges after v11 renumber:
front_matter 10–210, paper1 1010–1150, paper2 2010–2140, paper3 3010–3130,
audit 4010–4020, unified 5010, cover 6010, outreach 7010, handout 8010.

### Path A — Pipedream PostgreSQL connector (recommended for Perplexity Computer)

`postgresql__pipedream` is an account-level connector. Once the
maintainer wires it to Railway it stays available in every new
Perplexity session.

```python
# In a fresh Perplexity Computer session
call_external_tool(
    source_id="postgresql__pipedream",
    tool_name="postgresql-execute-custom-query",
    arguments={"sql": "SELECT count(*) FROM ssot_brochure.chapters;"}
)
```

The connector is **read-write capable**, so every write must still
follow rule 3 (backup-first plan + dry-run + explicit go-ahead in the
same session). Reads are safe by default.

To bind the connector to Railway: open the Pipedream PostgreSQL config
in Perplexity Settings → Connectors, paste the Railway DSN, save. The
DSN never enters chat.

### Path B — Local Postgres mirror (recommended for sandbox builds)

When running the Rust pipeline inside a sandbox (Perplexity sandbox,
GitHub Actions, local dev), boot a local Postgres 17 and load a TSV
dump of the SSOT.

```bash
# In sandbox
export PATH="/usr/lib/postgresql/17/bin:$PATH"
mkdir -p /tmp/pgdata
initdb -D /tmp/pgdata -U postgres --auth-local=trust --auth-host=trust
pg_ctl -D /tmp/pgdata -l /tmp/pglog -o "-p 5433" start
createdb -p 5433 -U postgres railway
psql -p 5433 -U postgres -d railway -c "CREATE SCHEMA ssot_brochure;"
psql -p 5433 -U postgres -d railway -c "
  CREATE TABLE ssot_brochure.chapters (
    slug             text PRIMARY KEY,
    kind             text NOT NULL,
    order_key        int  NOT NULL,
    title            text NOT NULL,
    body_md          text NOT NULL,
    illustration_url text
  );
"

# Load the latest SSOT snapshot (TSV — produced by every audit's backup step)
psql -p 5433 -U postgres -d railway -c "
  \\copy ssot_brochure.chapters(slug,kind,order_key,title,body_md,illustration_url)
    FROM '/path/to/all_chapters_pre_vNN_TIMESTAMP.tsv'
    WITH (FORMAT csv, DELIMITER E'\t', HEADER true);
"

export DATABASE_URL="postgresql://postgres@127.0.0.1:5433/railway"
```

A canonical TSV snapshot is kept at the path printed by every audit
(see `docs/audits/build-*-vNN.md` → "Backups" section). The latest as
of v12 is `/tmp/pgbackup/all_chapters_pre_v12_20260529T135422Z.tsv`.
That path lives in a per-session sandbox and is **not** committed; the
maintainer should treat the TSV dump as ephemeral cache.

If no TSV is available, the agent must read from Path A or Path C and
re-export — never invent rows.

### Path C — Direct DSN from the maintainer's local `.env`

For Claude Code / Codex running on the maintainer's Mac:

```bash
# ~/.env (never committed)
export RAILWAY_SSOT_URL="postgresql://..."   # SET LOCALLY; NEVER PRINT
# or:
export DATABASE_URL="postgresql://..."

# Shell wrapper used in the MCP registration (see §5)
set -a && . ~/.env && exec ./target/release/trios-mcp-rag
```

The `.env` file stays on the Mac. The Rust binary reads
`RAILWAY_SSOT_URL` (preferred) or `DATABASE_URL`. Never echo, log, or
commit either variable's value. Any audit, runbook, or migration that
references the DSN must do so by **env-var name only**.

### Known non-paths (do not try)

Two paths look plausible but do not work — see the **Known non-paths**
section of [`docs/agent-rules/03-safety-railway-postgres.md`](../agent-rules/03-safety-railway-postgres.md)
for the full reasoning:

- The Perplexity Computer **custom-credentials HTTPS proxy** cannot
  route `libpq` wire-protocol traffic; saving a Postgres DSN as a
  custom credential does not give you a working SSOT connection.
- No **browser-side** tool (browser_task, fetch_url, vertical search)
  speaks `libpq`. Browsing the Railway dashboard is **not** an SSOT
  read path — it returns rendered HTML, not row data.

Use Path A / B / C above. If none works, stop and ask the maintainer
rather than improvising a fourth path.

## 4. Build & QA Workflow

Every build is a six-step loop, identical across versions:

```bash
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:/usr/lib/postgresql/17/bin:$PATH"
cd /path/to/trios-mcp-rag-repo

# 1. BACKUP (mandatory before any SSOT migration)
TS=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p /tmp/pgbackup
psql "$DATABASE_URL" -c "\COPY (SELECT slug,kind,order_key,title,body_md,illustration_url \
  FROM ssot_brochure.chapters ORDER BY slug) \
  TO '/tmp/pgbackup/all_chapters_pre_vNN_${TS}.tsv' \
  WITH (FORMAT csv, DELIMITER E'\t', HEADER true);"
cp templates/chapter.template.tex /tmp/pgbackup/chapter.template.tex.pre_vNN_${TS}

# 2. DRY-RUN (apply migration but ROLLBACK at the end)
sed 's/^COMMIT;$/ROLLBACK;/' docs/migrations/2026-MM-DD-vNN-fixes.sql > /tmp/dryrun.sql
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f /tmp/dryrun.sql
# expect: "v.. migration verification: all checks passed" + ROLLBACK

# 3. APPLY for real
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f docs/migrations/2026-MM-DD-vNN-fixes.sql
# expect: "all checks passed" + COMMIT

# 4. BUILD
cargo build --release
rm -rf generated/out generated/build
mkdir -p generated/out generated/build
./target/release/trios-mcp-rag build-pdf --book-mode \
  --out-dir generated/out --build-dir generated/build \
  --pdf-name GOLDEN_CHAIN_2026-MM-DD.pdf

# 5. QA GATES (all must pass)
PDF=generated/out/GOLDEN_CHAIN_2026-MM-DD.pdf
pdftotext -layout $PDF /tmp/qa.txt
grep -c '\\tbd'    /tmp/qa.txt   # expect 0
grep -c '\\status' /tmp/qa.txt   # expect 0
pdftoppm -r 110 -png -f 1 -l 1 $PDF /tmp/qa_cover
# visual QA on opener pages of changed chapters

# 6. PUBLISH
git add docs/audits/build-2026-MM-DD-vNN.md \
        docs/migrations/2026-MM-DD-vNN-fixes.sql \
        docs/migrations/2026-MM-DD-vNN-runbook.md
git -c user.email="agent@perplexity.local" -c user.name="trios-mcp-rag agent" \
    commit -m "feat(brochure): vNN — X P0 + Y P1 fixes"
git push origin docs/agent-wake-up
# then refresh trinity-s3ai via scripts/refresh_compendium.sh
```

The two most recent audits (v11, v12) follow this template byte-for-byte
and can be used as worked examples.

## 5. MCP Registration (Claude Code only)

```bash
# In the trios-mcp-rag working tree
cargo build --release

# Wrapper reads .env so the DSN never lands in Claude's config
claude mcp add trios-mcp-rag \
  -- sh -c 'set -a && . ./.env && exec ./target/release/trios-mcp-rag'
claude mcp list
# restart the Claude Code session — MCP tools load at session start
```

The wrapper pattern is mandatory: passing the DSN through `--env` or
inline in the `claude mcp add` invocation leaks it into Claude's
config file. Per rule 4, this is forbidden.

## 6. Cross-Session Continuity Checklist

When the maintainer says "продолжай в новой сессии" (continue in a new
session), the new agent must:

1. **Load the three skills** (§1).
2. **Read this bootstrap doc** end-to-end.
3. **Read the latest audit** under `docs/audits/build-*-vNN.md` for
   pending P2 items, deferred B-class issues, and the last accepted
   numeric baseline (sha256, page count, file size).
4. **Confirm the SSOT connection** — try Path A first, fall back to B,
   then C. If none work, **stop and report** (rule: do not silently
   relax a rule).
5. **Sync the working branch** —
   `git pull origin docs/agent-wake-up`.
6. **Re-check the live commit on trinity-s3ai/main** — if the PDF
   commit there points at an older v than the trios-mcp-rag head,
   trigger `scripts/refresh_compendium.sh` to re-sync.

## 7. Forbidden Patterns

These will get the agent blocked by the maintainer and must never
appear in chat, in commits, or in generated artefacts:

- Printing or logging `$DATABASE_URL`, `$RAILWAY_SSOT_URL`,
  `$RAILWAY_TOKEN`, or any other secret value.
- Replacing the pandoc + tectonic pipeline with a Python /
  ReportLab / wkhtmltopdf / generic-text path.
- Writing claims of "prize" / "Nobel" / "field medal" as deliverables
  in any public artefact. These are external-validation standards
  only.
- Editing `ssot_brochure.chapters` without a same-session backup,
  dry-run, and explicit "go ahead" from the maintainer (rule 3).
- Adding non-English public-facing repo content (English-only per
  rule 7; bilingual TRIOS PhD README block is the documented
  exception).
- Inventing SSOT rows. If the connection is down, stop and ask.

## 8. Quick Reference Links

- Latest audit: [`docs/audits/build-2026-05-29-v12.md`](../audits/build-2026-05-29-v12.md)
- Latest migration: [`docs/migrations/2026-05-29-v12-fixes.sql`](../migrations/2026-05-29-v12-fixes.sql)
- Latest runbook: [`docs/migrations/2026-05-29-v12-runbook.md`](../migrations/2026-05-29-v12-runbook.md)
- Wave 22 cross-repo ledger: [`trinity-s3ai/WAVE22_STATUS.md`](https://github.com/gHashTag/trinity-s3ai/blob/main/WAVE22_STATUS.md)
- Published PDF: [`trinity-s3ai/releases/GOLDEN_CHAIN_compendium_v12.pdf`](https://github.com/gHashTag/trinity-s3ai/blob/main/releases/GOLDEN_CHAIN_compendium_v12.pdf)
- Operating rules: [`AGENTS.md`](../../AGENTS.md), [`CLAUDE.md`](../../CLAUDE.md), [`docs/agent-rules/`](../agent-rules/)

---

*Last updated: 2026-05-29 (v12 build).*
