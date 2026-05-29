# 10 — Next-Wave Workflow (v9 → v16 pattern, normative)

Every "next wave" / "critic-proof pass" on the GOLDEN CHAIN PDF follows
the same five-step pattern. **Nine consecutive waves** have used it
(v9, v10, v11, v12 — rebuild waves; v13, v14, v15, v16, v17 —
audit-only waves on the post-v12 baseline `f7c36a7`,
sha256 `6d2e29ed…`). Every deviation has caused drift or re-work.
This rule captures the pattern so future agents do not re-invent it.

Audit-only waves (v13–v17) skip steps 2–4 but still produce step 1
(`docs/audits/<wave>.md`) and step 5 (cross-repo / skill-mirror refresh).
This distinction was introduced in v17 P0.2 after `agent-bootstrap.md`'s
"Latest migration / runbook" pointer was wrongly flagged as drift
for four waves running.

This rule is normative. If you are running a wave that does not fit
this shape, stop and ask before proceeding — there is almost always a
way to express the work in this pattern.

## The five steps

```
1. Forensic audit       → docs/audits/<wave>.md
2. Migration SQL        → docs/migrations/<wave>/*.sql  (+ dry-run output)
3. Runbook              → docs/runbooks/<wave>.md
4. SSOT snapshot        → docs/agents/ssot-snapshot/chapters-post-<wave>.tsv
5. Cross-repo refresh   → trinity-s3ai README via scripts/refresh_compendium.sh
```

Each step has an output artefact in the repo. A wave is not done until
all five artefacts exist and the PDF has been rebuilt and shared.

---

## Step 1 — Forensic audit

**Output:** `docs/audits/<wave-slug>.md`.

Read the current SSOT, the previous wave's audit, and the latest PDF.
List anomalies (P0 / P1 / P2 / SSOT-only / pipeline-only / chapter-only).
Number them sequentially across the file. Each anomaly has:

- **Severity** (P0 = wrong claim or build-breaking, P1 = visible drift,
  P2 = cosmetic).
- **Evidence** (file + line, or SQL query + result).
- **Proposed fix** (SQL UPDATE / template edit / new rule).
- **Rollback** (one-liner SQL or `git revert <sha>`).

Do **not** apply fixes in this step. The audit is a read-only document.

## Step 2 — Migration SQL (and dry-run)

**Output:** `docs/migrations/<wave-slug>/*.sql` + `*.dry-run.txt`.

For each P0 / P1 anomaly that needs an SSOT change:

1. Write a backup statement first
   (`CREATE TABLE ssot_brochure._pre_<wave>_<slug> AS SELECT * FROM ...`).
2. Write the UPDATE / INSERT statement.
3. Run `EXPLAIN` and a row-count dry-run; capture in `*.dry-run.txt`.
4. Wait for explicit human "go ahead" in the same session before running
   the live UPDATE. Read-only default (rule 03) applies; this is the
   write-gate exception path.

Each migration file is named `NN-short-slug.sql` where `NN` is the
sequential index inside the wave (`01-fix-fm13-citation.sql`, etc.).

## Step 3 — Runbook

**Output:** `docs/runbooks/<wave-slug>.md`.

Step-by-step recipe to reproduce the wave from a clean checkout:

1. Branch / checkout sha.
2. Run audit (`docs/audits/<wave>.md`) — humans read this.
3. Apply migrations in order (with backup + dry-run + go-ahead per file).
4. Rebuild PDF via the canonical command (rule 00).
5. Run QA checklist (`docs/qa/brochure-pdf-checklist.md`).
6. Refresh SSOT snapshot (step 4).
7. Refresh trinity-s3ai compendium (step 5).
8. Update shared asset `GOLDEN_CHAIN_<date>` (use the same `name` field
   so versioning works in the Perplexity Computer UI).

A runbook is **executable prose** — every command must be a copy-paste
shell line, not a description.

## Step 4 — SSOT snapshot refresh

**Output:** `docs/agents/ssot-snapshot/chapters-post-<wave-slug>.tsv` +
sha256 in the bootstrap doc.

Run:

```bash
psql "$DATABASE_URL" \
  -c "\\copy (SELECT slug, kind, order_key, title, body_md, illustration_url FROM ssot_brochure.chapters ORDER BY order_key, slug) TO STDOUT WITH (FORMAT csv, DELIMITER E'\\t', QUOTE E'\\b', HEADER true)" \
  > docs/agents/ssot-snapshot/chapters-post-<wave>.tsv
sha256sum docs/agents/ssot-snapshot/chapters-post-<wave>.tsv
```

Replace the `chapters-post-<previous>.tsv` symlink (or rename the
previous file) so the bootstrap doc always points to the current
snapshot. Update `docs/agents/agent-bootstrap.md` §3 Path B with the
new sha256.

The snapshot is the **read-only mirror** used by agents running
without Railway access (Path B in the bootstrap). It carries only the
6 render-essential columns; the W38 trigger columns (`sha256`,
`word_count`, `byte_size`, `updated_at`) live only in Railway.

## Step 5 — Cross-repo refresh (trinity-s3ai)

**Output:** new commit in
[gHashTag/trinity-s3ai](https://github.com/gHashTag/trinity-s3ai)
under `WAVE<NN>/`.

```bash
cd /path/to/trinity-s3ai
./scripts/refresh_compendium.sh /path/to/trios-mcp-rag/generated/out/GOLDEN_CHAIN_<date>.pdf
git add -A && git commit -m "feat: WAVE<NN> v<wave> PDF refresh

- New PDF: <pages> pp, <size> MB, sha256 <hash>
- Source: gHashTag/trios-mcp-rag@<sha>
- Wave: <one-line summary>"
git push
```

The trinity-s3ai README must include a preview image (PDF page 1
rendered to PNG) and a direct link to the PDF. The
`scripts/refresh_compendium.sh` helper handles both. If the helper
does not exist in trinity-s3ai yet, port it from this repo before
running the wave.

---

## What is *not* a "next wave"

These are different workflows; do not force them into this pattern:

- **Hot-fix on the live SSOT** (rule 03 emergency path). Use a single
  audit + migration + runbook combined into one short doc.
- **Pipeline-only change** (template / Lua filter / `pipeline.rs`).
  No migration, no snapshot; a PR + new audit suffices.
- **Skill / rule update** (this very file).
  Lives under `docs/agent-rules/` and is mirrored into the user-scope
  skill `trios-mcp-rag` — see `docs/agents/agent-bootstrap.md` §1.
- **Single chapter rewrite from chat input.** Treat as a hot-fix; do
  not invent a wave for a one-row change.

## Shared-asset discipline

Every wave produces a new `GOLDEN_CHAIN_<date>.pdf`. **Use the same
`name` field** (e.g. `GOLDEN_CHAIN_2026-05-29`) across waves where the
date is the same; the Perplexity Computer UI then shows versions
side-by-side. Bumping the filename to `<date>-v13.pdf` defeats this and
forces the user into a flat list of orphan PDFs.

## Skill mirror link rewrite

When step 5 mirrors `docs/agent-rules/*.md`, `docs/qa/*.md`, or
`docs/agents/agent-bootstrap.md` into the user-scope skill
`trios-mcp-rag/references/`, **any link that uses an upstream-repo
relative path** (`../../scripts/...`, `../../.pre-commit-config.yaml`,
`../agent-rules/...`, `../qa/...`) MUST be rewritten to an **absolute
GitHub URL** of the form

```
https://github.com/gHashTag/trios-mcp-rag/blob/main/<path>
```

**Why.** From inside the repo, `../../scripts/verify-ssot-integrity.sh`
resolves to a real file. From inside the skill, the same string
resolves to `~/workspace/skills/user/scripts/...` which does not
exist — the skill workspace has no `scripts/` directory. v15
introduced 10 such broken links by mirroring rule files verbatim; v16
fixed them and added this rule.

**Procedure.** After running `cp docs/agent-rules/NN-*.md
references/NN-*.md` etc., run:

```bash
# Inside the skill references/ directory.
# Covers every upstream subdirectory the skill mirrors from:
#   ../../<repo-root-file>, ../agent-rules/, ../qa/, ../rag/,
#   ../literature/, ../audits/, ../migrations/  (file form and trailing-slash directory form).
for f in *.md; do
  sed -i -E \
    -e 's#\]\(\.\./\.\./([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/\1)#g' \
    -e 's#\]\(\.\./agent-rules/\)#](https://github.com/gHashTag/trios-mcp-rag/tree/main/docs/agent-rules/)#g' \
    -e 's#\]\(\.\./agent-rules/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/agent-rules/\1)#g' \
    -e 's#\]\(\.\./qa/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/qa/\1)#g' \
    -e 's#\]\(\.\./rag/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/rag/\1)#g' \
    -e 's#\]\(\.\./literature/\)#](https://github.com/gHashTag/trios-mcp-rag/tree/main/docs/literature/)#g' \
    -e 's#\]\(\.\./literature/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/literature/\1)#g' \
    -e 's#\]\(\.\./audits/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/audits/\1)#g' \
    -e 's#\]\(\.\./migrations/([^)]+)\)#](https://github.com/gHashTag/trios-mcp-rag/blob/main/docs/migrations/\1)#g' \
    "$f"
done
```

**Verification gate.** `grep -nE '\]\(\.\./' references/*.md` must
return **no matches** for any file after the rewrite. If a new
upstream subdirectory is introduced in a future wave, extend the
rewriter and update this gate before mirroring.

## Link-rot pre-flight (added v16)

A wave that claims to fix link rot or add cross-references MUST
first verify that **every link it adds resolves**. For each new
link:

  - **Repo-relative path:** `test -e "$path"` must succeed before
    the commit.
  - **Absolute URL:** `curl -fsSLI "$url" >/dev/null` must succeed
    (HTTP 200) before the commit. If the wave is offline-only, mark
    such links explicitly with `<!-- TODO(vN+1): verify URL -->`.

v15 violated this by linking to `docs/audits/build-2026-05-29-v13.md`
from README/CLAUDE/AGENTS without first checking that the file
existed (it did not). v16 reconstructed the file and codified the
rule.

**Executable enforcement (added v17).** Prose discipline was not enough
— v16 itself orphaned its own audit doc by *creating* the file without
linking it from any entry point (the inverse failure mode of v15's
broken-target bug). v17 ships [`scripts/check-link-rot.sh`](../../scripts/check-link-rot.sh)
with three sub-checks:

  1. **Audit-doc orphan scan** — every `docs/audits/build-*-vNN.md` in
     the last 5 versions must be referenced from at least one of
     `README.md`, `CLAUDE.md`, `AGENTS.md`,
     `docs/agents/agent-bootstrap.md`.
  2. **Local `.md` link resolution** — every `](path.md)` outside the
     `skills/` mirror must resolve on disk.
  3. **Latest-audit pointer freshness** — the `^- Latest audit:` line
     in `docs/agents/agent-bootstrap.md` must point at the
     highest-numbered audit on disk.

Exit codes: `0` clean, `1` broken link, `2` orphaned audit, `3` stale
pointer. Run from the repo root **before** committing any wave that
adds files under `docs/audits/`, edits the "Recent audits" lists, or
touches `docs/agents/agent-bootstrap.md`. The pre-commit framework
(rule 03 §"Bootstrap install") may invoke this script as a local hook,
but at minimum every wave's verification-gates list MUST include
`scripts/check-link-rot.sh` exits `0`. v16's orphan failure mode is
the regression test for this script.

## Cross-references

- `docs/agents/agent-bootstrap.md` — cross-session entry point.
- `docs/agent-rules/03-safety-railway-postgres.md` — write-gate rule
  (also lists "known non-paths" so future agents don't waste credits).
- `docs/agent-rules/08-mcp-registration.md` — MCP server registration
  discipline used by Claude Code peers reading from the same SSOT.
- `docs/agent-rules/09-audit-and-rag-coverage.md` — audit gates that
  step 1 of this workflow must clear.
- `docs/qa/brochure-pdf-checklist.md` — QA bar a wave must clear.
- Past audits: `docs/audits/`. Past runbooks: `docs/runbooks/`. Past
  migrations: `docs/migrations/`.
