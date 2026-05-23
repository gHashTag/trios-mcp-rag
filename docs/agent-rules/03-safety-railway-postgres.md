# 03 — Safety: Railway / Postgres Writes and Secrets

## Default posture: read-only

Every tool exposed by `trios-mcp-rag` today is read-only against the
SSOT. The agent contract is to keep it that way unless the user
explicitly authorises a write for a specific change.

`search_chapters`, `get_chapter`, `list_chapters`, `forbidden_audit`,
`build_cover`, and `build_pdf` perform only `SELECT`-class queries.
Any agent-initiated `INSERT` / `UPDATE` / `DELETE` / DDL is out of
scope for this repo's standard usage.

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

Not:

> "Connect using `postgresql://user:hunter2@…`."

The Rust pipeline in this repo already follows that contract (see
README → "Production safety"); the agent must do the same.

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
