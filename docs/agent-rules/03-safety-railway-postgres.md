# 03 — Safety: Railway / Postgres Writes and Secrets

## Default posture: read-only

All content and build tools exposed by `trios-mcp-rag` are read-only
against the SSOT by default. The agent contract is to keep normal usage
read-only unless the user explicitly authorises a write for a specific
change.

`search_chapters`, `get_chapter`, `list_chapters`, `forbidden_audit`,
`build_cover`, `build_pdf`, `build_book`, `get_claim_status`,
`list_claims`, `get_honest_counters`, `preview_chapter_update`, and
`preview_chapter_insert` perform no SSOT writes. Preview tools may show
SQL templates but must not execute them.

`backup_ssot` is the only standard tool that can execute DDL, and only
when called with explicit confirmation. Any agent-initiated `INSERT` /
`UPDATE` / `DELETE` beyond the backup step is out of scope for this
repo's standard usage unless the write gate below has been completed.

## When a write is being considered

Before any write to the Railway Postgres SSOT, the agent MUST satisfy
all of the following, in order:

1. **Backup-first plan, in writing.** State, in the session, exactly
   which table(s) and which rows will change, and how the previous
   state will be restorable. "Trust me" is not a plan.
   - Acceptable: a `pg_dump` of the affected schema to a known path, or
     a `CREATE TABLE … AS SELECT *` snapshot of the affected rows,
     timestamped, with the restore command spelled out.
   - Not acceptable: "I'll be careful", or relying on Railway's
     platform backup without confirming retention and restore steps.
2. **Dry-run.** Show the exact SQL (or the exact diff for bulk
   operations) and the row count it would affect, without executing.
3. **Explicit, in-session confirmation from the user.** A prior "you
   can edit chapters" or a CLAUDE.md note does **not** count. The
   confirmation must be for *this specific change*, in *this session*.
4. **Reversibility check.** If the change is not cleanly reversible
   from the backup in step 1, stop and re-plan.

If any step fails, the write does not happen.

## Secrets discipline

The following values must never appear in:

- repository files
- commit messages
- PR descriptions
- chat output that may be logged or shared
- build artefacts, including generated Markdown, LaTeX, PDF metadata

Sensitive values include, but are not limited to:

- `DATABASE_URL` value (DSN, including the password component)
- `RAILWAY_SSOT_URL` value
- Railway API tokens, project tokens, deploy tokens
- Postgres user passwords
- Any value pulled from a Railway environment / variables tab
- API keys for any third-party service used during a build

Refer to these by **environment variable name only**:

> "Connect using `DATABASE_URL` from the environment."

Not: "Connect using the literal connection string copied from Railway."

The Rust pipeline in this repo already follows that contract (see
README → "Production safety"); the agent must do the same.

### Reference implementation

The secrets-discipline gate is enforced at commit time by
[`.pre-commit-config.yaml`](../../.pre-commit-config.yaml) and
[`.gitleaks.toml`](../../.gitleaks.toml). The active hooks are:

  - **`gitleaks v8.21.0`** with two custom rules — `postgres-dsn`
    matches any `postgres(ql)?://user:pass@host` form, and
    `railway-tcp-proxy` matches Railway's TCP-proxy hostname
    patterns. These fire before the commit object is created;
    bypassing them requires an explicit `--no-verify`, which is
    out-of-policy without a same-session `go ahead`.
  - **`pre-commit-hooks v4.6.0`** baseline (whitespace, large-file,
    merge-conflict-marker, private-key detection).

A wave that adds a new secret class (e.g. a new third-party API
key) MUST add the matching gitleaks rule in the same commit. The
rule and the hook are the only sanctioned places where rule 03
leaves the documentation layer and becomes executable.

## If a secret is accidentally exposed

1. Stop the current operation.
2. Tell the user, in plain language, what was exposed and where.
3. Recommend rotation (Railway → Variables → regenerate; rotate the
   Postgres user password if applicable).
4. Do not include the leaked value in the rotation recommendation.
5. If the leak landed in a commit, propose the cleanup path (force
   rewrite + rotation) but **do not force-push without explicit
   confirmation** — destructive history rewrites have their own
   blast-radius problem.

## Tokens and CI

Same rules apply to CI: agents must not embed Railway / Postgres
credentials in workflow files, action inputs, or container build args.
Use GitHub Actions secrets / Railway-side env injection, by name.

## Known non-paths (do not waste time on these)

These approaches have been tried and do not work. They are documented
so future agents do not re-attempt them.

### Custom-credentials HTTPS proxy for Postgres TCP

The Perplexity Computer `custom-credentials` mechanism is an HTTPS
proxy that injects bearer tokens into outbound HTTPS requests. It
cannot route Postgres TCP traffic (libpq protocol over port 5432) —
the wire protocols are incompatible. Attempts to set
`api_credentials=["custom-cred:railway.app"]` for `psql` calls will
fail at connection time with TLS / handshake errors, not with a clear
"not supported" message.

**Use one of these instead** (documented in
`docs/agents/agent-bootstrap.md` §3):

- **Path A — Pipedream PostgreSQL connector.** Routes via Pipedream's
  managed proxy. Requires the connector to be in CONNECTED state and
  the DSN refreshed in Settings when it expires.
- **Path B — Local mirror from TSV snapshot.** Restore
  `docs/agents/ssot-snapshot/chapters-post-<wave>.tsv` into a local
  Postgres 17 instance. Read-only; carries 6 columns. Sufficient for
  RAG queries and PDF rebuilds.
- **Path C — Local `.env` DSN with shell wrapper.** The standard
  `set -a && . ./.env && exec ...` pattern used by Claude Code
  registration (rule 08).

### Direct Railway Postgres from in-browser tools

No browser-side tool (Playwright, browser_task, etc.) can speak
libpq. The Railway dashboard's web SQL console is the only
in-browser path, and it lacks the audit / backup discipline this rule
requires; do not use it for writes.
