# AGENT_WAKEUP.md — Single-Page Wake-Up Card

Read this first when starting any AI session against this repo. It is
a one-page summary of [`AGENTS.md`](AGENTS.md) +
[`docs/agent-rules/`](docs/agent-rules/) +
[`docs/literature/`](docs/literature/), plus the host-specific
connection commands.

## 8 Hard Rules

1. **Pipeline.** Rust `trios-phd` / TRIOS MCP → Railway Postgres
   SSOT → Markdown → pandoc → LaTeX → tectonic → PDF. No Python /
   ReportLab / WeasyPrint / wkhtmltopdf substitution.
2. **SSOT.** Postgres `ssot_brochure.chapters` is the only authority;
   README / brochure / PDF / articles are derived artefacts.
3. **Read-only by default.** Writes require backup-first plan + dry-run
   + explicit in-session human "go ahead". No exceptions for "small
   fixes".
4. **No secret leakage.** Never print or commit DSNs, Railway tokens,
   passwords, or any value from `DATABASE_URL` /
   `RAILWAY_SSOT_URL` / `TRIOS_DATABASE_URL`. Reference them by
   env-var name only.
5. **Claim-status framing.** Verified / Empirical fit / Open
   conjecture / High-risk / Retracted. No prize or Nobel claims as
   deliverables — only as long-term external-validation standards.
6. **QA checklist.** Run [`docs/agent-rules/05-brochure-qa-checklist.md`](docs/agent-rules/05-brochure-qa-checklist.md)
   and [`docs/qa/brochure-pdf-checklist.md`](docs/qa/brochure-pdf-checklist.md)
   before declaring a build done.
7. **English public content.** Public repo artefacts are
   English-only; chat with the maintainer may be Russian.
8. **`TRIOS_PHD_NO_IMAGE_TRAIN`.** Heroes are required on chapter
   openers but must be semantically anchored to nearby text. Enforce
   with soft keep-together (penalties + `\needspace`), not
   `\clearpage` per section.

## 9 Literature-Grounded Refinements (rule 07)

See [`docs/agent-rules/07-literature-grounded-refinements.md`](docs/agent-rules/07-literature-grounded-refinements.md).

1. RAGAS CI gate (faithfulness ≥ 0.80, context recall ≥ 0.75).
2. `falsification_path` mandatory for every Open conjecture.
3. Adjacent-literature anchoring — no external DOI ⇒ capped at
   Open conjecture.
4. Index hygiene pre-build (pgvector HNSW + tsvector GIN).
5. Epistemic-label propagation through the Lua filter.
6. `alt_text` non-nullable in the image manifest.
7. No-image-train via penalty, not `\clearpage`.
8. Tectonic version pinning + `sha256` reproducible-build hash.
9. Extended language scan (non-English markers + Open-conjecture
   strong-assertion inconsistency).

## How to wake up an agent

Common prerequisites for every host:

```bash
# 1. Build (or use the prebuilt) MCP server binary
cargo build --release

# 2. Provide your DSN locally via .env — NEVER commit this file
cp .env.example .env
# edit .env and set TRIOS_DATABASE_URL (or DATABASE_URL) — env-var name only

# 3. Make sure pandoc + tectonic are on PATH
pandoc --version && tectonic --version
```

### Claude Code

> ⚠️ **Use `-s user` (global) — not the default local scope.**
> Default scope is *local*: the server is registered only for the
> current directory and is invisible to agents started elsewhere.
> `-s user` writes the entry to your user config and makes it
> available in **all** projects / sessions.
>
> ⚠️ **Do not pipe `claude mcp add`** (no `echo ... | claude mcp add`).
> The confirmation prompt gets swallowed and the entry is silently
> not written.
>
> ⚠️ **Use an absolute path** to the working directory — a user-scope
> entry runs from any cwd, so `./target/...` will break outside the
> build folder.

```bash
# Replace /ABS/PATH/trios-mcp-rag with the absolute path to your clone.
claude mcp add trios-mcp-rag -s user -- \
  sh -c 'cd /ABS/PATH/trios-mcp-rag && set -a && . ./.env && exec ./target/release/trios-mcp-rag'

claude mcp list                    # trios-mcp-rag … ✓ Connected
claude mcp get trios-mcp-rag       # Scope: User (available in all your projects)
```

**Restart the Claude Code session** after registering — MCP tools are
loaded at session start. Expect 13 tools to appear
(`search_chapters`, `get_chapter`, `build_pdf`, …).

**Reset / re-register** if a previous (broken) entry exists:

```bash
claude mcp remove trios-mcp-rag                 # remove user-scope entry
claude mcp remove trios-mcp-rag --scope local   # remove project-local leftover, if any
claude mcp list                                  # confirm clean state
# then re-run the `claude mcp add … -s user …` command above.
```

The `sh -c 'cd /ABS/PATH && set -a && . ./.env && exec …'` wrapper
keeps the DSN out of Claude Code's configuration file — it is
resolved from `./.env` at server-start time only. The leading `cd`
is required so `./.env` resolves regardless of the agent's cwd.

### Cursor / Windsurf / opencode

Use the host's MCP-server settings UI and add a server entry pointing
to `./target/release/trios-mcp-rag`. Configure the host to load
environment from `./.env` before launching the server (the exact UI
varies by host). Verify with the host's MCP-tools panel.

### Perplexity Computer

1. Open [Manage skills](https://www.perplexity.ai/computer/skills).
2. Upload [`docs/skills/trios-mcp-rag.zip`](docs/skills/trios-mcp-rag.zip)
   and [`docs/skills/trios-research-canon.zip`](docs/skills/trios-research-canon.zip)
   under "User skills".
3. The descriptions include trigger phrases; the platform auto-loads
   them when a relevant task arrives.

Perplexity Computer does not directly run the local MCP binary — it
uses the skills to know the operating rules and the Quickstart, then
falls back to its own RAG / GitHub connector for repo work. For
end-to-end PDF builds, drive Claude Code locally.

### Generic agentskills-compatible host

Unzip `docs/skills/*.zip`, point your host's skill loader at the
resulting directory, and follow your host's MCP-server registration
docs to spawn `./target/release/trios-mcp-rag` with `./.env`.

## Build a fresh GOLDEN CHAIN PDF

After the agent is awake:

```bash
trios-mcp-rag build-pdf --dry-run

trios-mcp-rag build-pdf \
  --book-mode \
  --out-dir generated/out \
  --pdf-name "GOLDEN_CHAIN_$(date +%F).pdf"
```

Reference baseline: **88 chapters → 327 pages, ~11 MB, cover
inserted**, database read **read-only**.

Then run the QA checklist
([`docs/qa/brochure-pdf-checklist.md`](docs/qa/brochure-pdf-checklist.md)
and [`docs/rag/PDF_QA_CHECKLIST.md`](docs/rag/PDF_QA_CHECKLIST.md))
before sharing the artefact.

---

If anything in this card conflicts with chat, the rules win unless the
maintainer explicitly overrides them in the same session for the
specific change.
