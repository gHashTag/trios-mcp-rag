# trios-mcp-rag

**MCP server** (Model Context Protocol) providing RAG (Retrieval-Augmented Generation) access to the **GOLDEN BRIDGE** chapter database hosted on Railway PostgreSQL.

Exposes MCP tools that let AI agents (Claude Code, Cursor, Windsurf, opencode, etc.) search, read, audit, and rebuild the Trinity S³AI compendium from the Railway/Postgres SSOT.

> **AI agents and RAG runs:** read [AGENTS.md](AGENTS.md) before
> generating PDFs, modifying the build pipeline, or touching the
> Railway Postgres SSOT. The full rule set lives in
> [`docs/agent-rules/`](docs/agent-rules/) and covers the canonical
> pipeline, SSOT discipline, PDF style, write-safety, claim-status
> framing, brochure QA, language policy, literature-grounded
> refinements, MCP registration, audit-and-RAG-coverage gates, and the
> next-wave-workflow pattern.
>
> **TL;DR for new sessions:** open [`AGENT_WAKEUP.md`](AGENT_WAKEUP.md)
> for a one-page wake-up card (rules + connection commands for every
> host), then read
> [`docs/agents/agent-bootstrap.md`](docs/agents/agent-bootstrap.md)
> for the full bootstrap — skill loading, repo map, three Postgres SSOT
> connection paths, build + QA workflow, MCP registration recipe.

---

## Rule Index

The normative rule files in [`docs/agent-rules/`](docs/agent-rules/)
are numbered. New contributors and external readers should skim the
full index — every rule was added in response to a real audit
finding. Curated audits live in [`docs/audits/`](docs/audits/);
recent ones include
[`build-2026-05-29-v13.md`](docs/audits/build-2026-05-29-v13.md),
[`build-2026-05-29-v14.md`](docs/audits/build-2026-05-29-v14.md), and
[`build-2026-05-29-v15.md`](docs/audits/build-2026-05-29-v15.md).

- [`00-canonical-pipeline.md`](docs/agent-rules/00-canonical-pipeline.md) — Rust + pandoc + tectonic is the only supported renderer.
- [`01-ssot-and-derived-artifacts.md`](docs/agent-rules/01-ssot-and-derived-artifacts.md) — Postgres `ssot_brochure.chapters` is authoritative; files are derived.
- [`02-pdf-style.md`](docs/agent-rules/02-pdf-style.md) — white academic title page, serif typography, S³AI hero panels, no teal corporate covers.
- [`03-safety-railway-postgres.md`](docs/agent-rules/03-safety-railway-postgres.md) — read-only by default; writes require backup, dry-run, explicit `go ahead`; no DSN / token leakage.
- [`04-claim-status.md`](docs/agent-rules/04-claim-status.md) — Verified / Empirical fit / Open conjecture / High-risk / Retracted; no Nobel claims as deliverables.
- [`05-brochure-qa-checklist.md`](docs/agent-rules/05-brochure-qa-checklist.md) — pre-publish QA: duplicates, stale markers, secrets, language, qpdf / pdfinfo / pdftotext.
- [`06-language-policy.md`](docs/agent-rules/06-language-policy.md) — public repo artefacts are English-only.
- [`07-literature-grounded-refinements.md`](docs/agent-rules/07-literature-grounded-refinements.md) — RAGAS CI thresholds, `falsification_path` gate, `alt_text` non-null, tectonic pinning, each with explicit `Status:` line.
- [`08-mcp-registration.md`](docs/agent-rules/08-mcp-registration.md) — `-s user`, absolute wrapper path, no piped install, reset scopes before re-adding, restart host.
- [`09-audit-and-rag-coverage.md`](docs/agent-rules/09-audit-and-rag-coverage.md) — embedding coverage, stale-embedding detector, schema-vs-rule consistency, claim-status sweep. Reference implementation: [`scripts/verify-ssot-integrity.sh`](scripts/verify-ssot-integrity.sh).
- [`10-next-wave-workflow.md`](docs/agent-rules/10-next-wave-workflow.md) — normative five-step pattern for every critic-proof pass: forensic audit → migration SQL → runbook → SSOT snapshot → cross-repo refresh.

---

## Quickstart — wake up an AI agent

Get any MCP-aware AI agent (Claude Code, Cursor, Windsurf, opencode,
Perplexity Computer) into the same operating posture as the rules in
[`AGENTS.md`](AGENTS.md), then print a fresh GOLDEN CHAIN PDF.

### Common prerequisites

```bash
# 1. Build (or use the prebuilt) MCP server binary
cargo build --release

# 2. Provide DSN locally via .env — NEVER commit it
cp .env.example .env
# edit .env, set TRIOS_DATABASE_URL (or DATABASE_URL) — env-var name only

# 3. Confirm pandoc + tectonic are on PATH
pandoc --version && tectonic --version
```

The `.env` file is read at server-start time only; the DSN never enters
any host's configuration file. This satisfies rule 4 of
[`AGENTS.md`](AGENTS.md).

### Claude Code

> ⚠️ **Use `-s user` (global), not the default local scope.**
> The default scope is *local* — the server is registered only for the
> current project directory and is invisible to agents running from
> anywhere else. Always pass `-s user` so the entry lives in your user
> config and every project / agent session sees it.
>
> ⚠️ **Do not pipe the `add` command** (`echo ... | claude mcp add ...`)
> — the confirmation prompt gets swallowed and the entry is silently
> not written. Run it directly.
>
> ⚠️ **Use an absolute path to the binary**, not `./target/...` — a
> user-scope entry is executed from any working directory, so a
> relative path will fail outside the build folder.

```bash
# Replace /ABS/PATH/trios-mcp-rag with the absolute path to your clone.
claude mcp add trios-mcp-rag -s user -- \
  sh -c 'cd /ABS/PATH/trios-mcp-rag && set -a && . ./.env && exec ./target/release/trios-mcp-rag'

claude mcp list                    # should show: trios-mcp-rag … ✓ Connected
claude mcp get trios-mcp-rag       # Status: ✓ Connected; Scope: User (available in all your projects)
```

**Reset / re-register** if something went wrong (e.g. an earlier local-scope
entry, a stale test name, or a duplicate):

```bash
claude mcp remove trios-mcp-rag                 # remove user-scope entry
claude mcp remove trios-mcp-rag --scope local   # remove project-local leftover, if any
claude mcp list                                  # confirm empty / single clean entry
# then re-run the `claude mcp add … -s user …` command above.
```

**Restart the Claude Code session** after registering — MCP tools are
loaded at session start. After restart you should see all 13 tools
(`search_chapters`, `get_chapter`, `build_pdf`, …).

### Cursor / Windsurf / opencode

In each host's MCP-server settings, add an entry that launches
`./target/release/trios-mcp-rag` with environment loaded from `./.env`.
Verify with the host's MCP-tools panel. Detailed per-host guides:
[`Connection guides`](#connection-guides) section below.

### Perplexity Computer

1. Open [Manage skills](https://www.perplexity.ai/computer/skills).
2. Upload [`docs/skills/trios-mcp-rag.zip`](docs/skills/trios-mcp-rag.zip)
   and [`docs/skills/trios-research-canon.zip`](docs/skills/trios-research-canon.zip)
   under "User skills".
3. The descriptions include trigger phrases; Perplexity auto-loads them
   when a relevant task arrives.

For end-to-end PDF builds, drive Claude Code locally — Perplexity
Computer uses the skills for operating posture, not as the renderer.

### Generic agentskills-compatible host

Unzip `docs/skills/*.zip` and point your host's skill loader at the
resulting directory, then register `./target/release/trios-mcp-rag`
with your MCP layer.

### Build a fresh GOLDEN CHAIN PDF

Once the agent is awake:

```bash
trios-mcp-rag build-pdf --dry-run

trios-mcp-rag build-pdf \
  --book-mode \
  --out-dir generated/out \
  --pdf-name "GOLDEN_CHAIN_$(date +%F).pdf"
```

Reference baseline build (post-v12, 2026-05-29):
**69 chapters → 259 pages → ~3.5 MB**, cover inserted, database read
**read-only**. Reference sha256:
`6d2e29ed32cc92b4aea32a0c639f7f16c646d94e1aa4adba97787869ec79293d`.
See `docs/qa/brochure-pdf-checklist.md` for the full numeric baseline
and historical waves (v8 → v10 → v12).

Then run the QA checklist
([`docs/qa/brochure-pdf-checklist.md`](docs/qa/brochure-pdf-checklist.md)
and [`docs/rag/PDF_QA_CHECKLIST.md`](docs/rag/PDF_QA_CHECKLIST.md))
before sharing the artefact.

---

## Scientific Honesty Status Panel

This repo serves the **Trinity S³AI** compendium. The project follows a
verification-first discipline. Before citing any claim, check the
evidence ledger. **Note:** the first three rows below live in the
sister formalization repository
[`gHashTag/trinity-s3ai`](https://github.com/gHashTag/trinity-s3ai)
(theorem-level evidence ledger); the last three live in this repo.

| Document | Repo | Purpose |
|----------|------|---------|
| [`docs/CORRECTED_GAP_ANALYSIS.md`](https://github.com/gHashTag/trinity-s3ai/blob/main/docs/CORRECTED_GAP_ANALYSIS.md) | trinity-s3ai | Claim-by-claim mapping to repo evidence (file/theorem/PR/commit) |
| [`docs/RETRACTED_OR_UNVERIFIED_CLAIMS.md`](https://github.com/gHashTag/trinity-s3ai/blob/main/docs/RETRACTED_OR_UNVERIFIED_CLAIMS.md) | trinity-s3ai | Registry of withdrawn or hallucinated claims |
| [`docs/NOBEL_LEVEL_RESEARCH_PROGRAM.md`](https://github.com/gHashTag/trinity-s3ai/blob/main/docs/NOBEL_LEVEL_RESEARCH_PROGRAM.md) | trinity-s3ai | 5–10 year falsifiable research program (not a prize promise) |
| [`docs/RAG_TEST_PLAN.md`](docs/RAG_TEST_PLAN.md) | this repo | Local unit, MCP smoke, RAG quality, PDF, and Railway write-gate tests |
| [`docs/CHAIN_OF_CUSTODY_COMPETITORS.md`](docs/CHAIN_OF_CUSTODY_COMPETITORS.md) | this repo | Chain-of-custody proof competitor map for DePIN positioning |
| [`ROADMAP.md`](ROADMAP.md) | this repo | Implementation roadmap for MCP, PDF, SSOT, and custody-proof work |

**Current snapshot (trinity-s3ai `main`, 2026-05-24):**
- **1,762** machine-checked theorems (`Qed`/`Defined`)
- **5** real `Admitted.` (all cited or tagged `[OPEN_PROBLEM]`)
- **85** explicit Axioms/Conjectures/Parameters
- **14** refutation theorems (`refuted`)
- δ_CP = 3/φ² ≈ 65.66° **withdrawn** as physical prediction (PR #22, 5.6σ excluded)
- Alleged δ_CP ≈ −105° **does not exist** in repo (prior-agent hallucination)

**Rule:** No claim enters README, PDF, or public communication without a
pointer to evidence or an explicit `unverified` label. See
[`docs/agent-rules/04-claim-status.md`](docs/agent-rules/04-claim-status.md).

---

## Tools

| Tool | Description |
|------|-------------|
| `search_chapters` | Full-text search across all chapters (`ILIKE` on title + body) |
| `get_chapter` | Fetch full chapter content by slug |
| `list_chapters` | List all chapter slugs with metadata (kind, order, word count) |
| `forbidden_audit` | Scan all chapters for policy violations / prohibited terms |
| `build_cover` | Generate and optionally compile the GPT-2-style Leonardo chalk architect cover |
| `build_pdf` | Run the canonical SSOT → Markdown → pandoc → tectonic → PDF pipeline (dry-run by default) |
| `get_claim_status` | Search chapters for claim-status markers (Verified, Empirical fit, Open conjecture, High-risk, Falsified, Retracted, Unverified) |
| `list_claims` | Scan all chapters for claim-status vocabulary and return per-chapter summary |
| `get_honest_counters` | Return the corrected, audited snapshot of trinity-s3ai formal proof counters |
| `build_book` | Extended PDF pipeline with book-mode (TOC, chapter-level structure, dry-run by default) |
| `preview_chapter_update` | **Dry-run only.** Show SQL diff and word-count change for a proposed chapter update |
| `preview_chapter_insert` | **Dry-run only.** Prepare a parameterized INSERT plan for a proposed new SSOT chapter |
| `backup_ssot` | Create a timestamped backup table. Requires `confirm=true`; returns dry-run SQL otherwise |

## Prerequisites

- **Rust** 1.75+ (`rustup`)
- **PostgreSQL** with the `ssot_brochure.chapters` table populated

## Install

### Option A: Build from source

```bash
git clone https://github.com/gHashTag/trios-mcp-rag.git
cd trios-mcp-rag
cargo build --release
```

The binary will be at `target/release/trios-mcp-rag`.

### Option B: Install with cargo

```bash
cargo install --git https://github.com/gHashTag/trios-mcp-rag.git
```

## Configuration

### Environment variable

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |

Set the value through your shell, MCP client secret store, Railway
Variables, or CI secrets. Do not commit or paste the connection string.

```bash
export DATABASE_URL="<redacted>"
```

### Database schema

The server expects a `ssot_brochure.chapters` table with columns:

```sql
CREATE TABLE ssot_brochure.chapters (
    slug              TEXT PRIMARY KEY,
    kind              TEXT NOT NULL,
    order_key         INT  NOT NULL,
    title             TEXT NOT NULL,
    body_md           TEXT NOT NULL,
    illustration_url  TEXT,                        -- nullable; URL or NULL
    sha256            TEXT,                        -- recomputed by W38 trigger
    word_count        INT NOT NULL DEFAULT 0,      -- recomputed by W38 trigger
    byte_size         INT,                         -- octet_length(body_md)
    format            TEXT,                        -- 'md' default
    asset_sha         TEXT,                        -- FK to assets registry
    updated_at        TIMESTAMPTZ DEFAULT now()    -- bumped by W38 trigger
);
-- See docs/agent-rules/01-ssot-and-derived-artifacts.md for the
-- authoritative schema rule. Run `\d ssot_brochure.chapters` to verify.
```

## Connection guides

### Claude Code (claude.ai/code)

Add to your `.claude/settings.json`:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

Or use the absolute path to the binary:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "/path/to/trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

### Claude Desktop

Add to `claude_desktop_config.json`:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "/path/to/trios-mcp-rag",
      "args": [],
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

### Dual-server setup (trios-train + trios-rag)

If you also run [`trios-mcp`](https://github.com/gHashTag/trios-mcp) (the `tri` / `trios-igla` wrapper), register both servers side-by-side:

```json
{
  "mcpServers": {
    "trios-train": {
      "command": "/path/to/trios-mcp/target/release/trios-mcp",
      "env": {
        "TRIOS_TRI_BIN": "/path/to/tri",
        "TRIOS_IGLA_BIN": "/path/to/trios-igla"
      }
    },
    "trios-rag": {
      "command": "/path/to/trios-mcp-rag/target/release/trios-mcp-rag",
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

See [`examples/claude_desktop_config.json`](examples/claude_desktop_config.json) for a copy-paste template.

### Cursor IDE

1. Open **Settings → MCP**
2. Click **Add new MCP server**
3. Configure:

| Field | Value |
|-------|-------|
| Name | `trios-rag` |
| Type | `stdio` |
| Command | `/path/to/trios-mcp-rag` |
| Env | `DATABASE_URL=<redacted>` |

Or add to `.cursor/mcp.json` in your project root:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

### Windsurf

Add to `~/.windsurf/settings/mcp.json`:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

### opencode

Add to `.opencode/opencode.json` or `opencode.json` in your project root:

```json
{
  "mcp": {
    "trios-rag": {
      "type": "stdio",
      "cmd": "trios-mcp-rag",
      "env": {
        "DATABASE_URL": "<redacted>"
      }
    }
  }
}
```

### Any MCP client (generic)

This server uses the **stdio** transport (JSON-RPC 2.0 over stdin/stdout). It is compatible with any client that supports the MCP protocol specification `2024-11-05`.

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | DATABASE_URL=... trios-mcp-rag
```

### Docker

```bash
docker build -t trios-mcp-rag .

# Run as MCP server
docker run -i --rm \
  -e DATABASE_URL="<redacted>" \
  trios-mcp-rag
```

Then point your MCP client at the Docker command:

```json
{
  "mcpServers": {
    "trios-rag": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "-e", "DATABASE_URL=<redacted>", "trios-mcp-rag"]
    }
  }
}
```

## Usage examples

Once connected, your AI agent can use the tools:

```
User: Search for chapters about golden ratio in physics
Agent: [calls search_chapters(query="golden ratio physics")]
→ Returns matching chapters with snippets

User: What chapters exist?
Agent: [calls list_chapters()]
→ Returns all 80+ chapters with metadata

User: Get the full text of chapter "ch-01-introduction"
Agent: [calls get_chapter(slug="ch-01-introduction")]
→ Returns full chapter content in Markdown

User: Check for policy violations
Agent: [calls forbidden_audit()]
→ Returns "CLEAN" or lists violations
```

## Architecture

```
AI Agent (Claude/Cursor/opencode)
    │
    │  stdio (JSON-RPC 2.0)
    ▼
trios-mcp-rag
    │
    │  tokio-postgres
    ▼
PostgreSQL (ssot_brochure.chapters)
    │
    ├── 80+ chapters
    ├── Full-text search (ILIKE)
    └── Policy audit (forbidden terms)
```

The server speaks MCP protocol over stdio — each line is a JSON-RPC request, each response is a single JSON line. This is the standard transport for MCP servers.

## Railway deployment

### Postgres SSOT

1. Create a **PostgreSQL** service in your Railway project.
2. Copy the internal `DATABASE_URL` from the **Variables** tab.
3. Populate chapters via the ingest pipeline from the main [trios](https://github.com/gHashTag/trios) repo:
   ```bash
   cargo run -p trios-phd -- ingest-rag-chunks
   ```

### Deploy trios-mcp-rag as a Railway service

The repo includes a `Dockerfile` with the full PDF toolchain (`pandoc` + `tectonic` + Latin Modern Math fonts) and a `railway.toml` for zero-config deploy:

```bash
# 1. Link your repo to the Railway project
railway link --project <PROJECT_ID>

# 2. Deploy
railway up
```

Requirements:
- `DATABASE_URL` must be set in the service **Variables** tab (or auto-provisioned from the Postgres service).
- The container runs as an **stdio MCP server**. For remote MCP clients, use a local bridge (e.g., `npx mcp-remote`) or run the binary directly with `DATABASE_URL` exported.

## SSOT → PDF pipeline (`build_pdf` / `trios-mcp-rag build-pdf`)

The canonical Trios PhD build path is exposed both as an MCP tool
(`build_pdf`) and as a CLI subcommand (`trios-mcp-rag build-pdf …`):

```
Railway / Postgres SSOT
        │  read-only (ssot_brochure.chapters or ssot.chapters)
        ▼
Markdown (generated/build/main.md)
        │  pandoc  --template chapter.template.tex
        │          --lua-filter force-fullwidth-hero.lua
        ▼
LaTeX   (generated/build/main.tex)
        │  tectonic
        ▼
PDF     (generated/out/main.pdf)
```

### Dependencies

- `pandoc` on PATH (tested with 3.x)
- `tectonic` on PATH

No Python / ReportLab substitute is supported. The pandoc + tectonic
path is the only renderer per the R1 / CROWN warning carried over from
the parent `gHashTag/trios` repo.

### Image placement & dedup rules (must-read for agents)

Before editing chapters, the image manifest, the Lua filter, the LaTeX
template, or `src/pipeline.rs`, read the rules in [`docs/rag/`](docs/rag/):

- [`docs/rag/IMAGE_PLACEMENT.md`](docs/rag/IMAGE_PLACEMENT.md) — single
  source of truth for image placement and deduplication. Grep anchors:
  `TRIOS_PHD_IMAGE_PLACEMENT`, `TRIOS_PHD_IMAGE_DEDUP`,
  `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`,
  `TRIOS_PHD_STYLE_LOCK`.
- [`docs/rag/IMAGE_MANIFEST_SCHEMA.md`](docs/rag/IMAGE_MANIFEST_SCHEMA.md)
  — required SSOT image fields (`image_id`, `role`, `canonical_anchor`,
  `priority`, `caption`, `source`, `file_hash`, `allowed_repeat_policy`).
- [`docs/rag/PDF_QA_CHECKLIST.md`](docs/rag/PDF_QA_CHECKLIST.md) —
  blocking checks to run before sharing or committing a generated PDF.

If a PDF has duplicated or misplaced images, fix the SSOT / Markdown /
Lua filter / LaTeX template — never the exported PDF. See
`IMAGE_PLACEMENT.md` §9.

### Environment

- `DATABASE_URL` (or `RAILWAY_SSOT_URL` as a fallback) — Postgres DSN.
  Connection strings are read from the environment by name only; no
  secret value is logged, printed, or written to disk.
- `--database-url-env NAME` changes which variable is consulted.

### Production safety

- The pipeline reads only. It never executes `INSERT`, `UPDATE`,
  `DELETE`, or DDL against the SSOT.
- No DSN value is hard-coded; passing `DATABASE_URL` on the command
  line is not supported on purpose, to keep secrets out of shell
  history.
- `--dry-run` / `--check` validates env, dependencies, and template /
  filter paths and counts chapters without producing any artefact.

### CLI examples

```bash
# Dry-run: validate env, dependencies, paths, and table access.
trios-mcp-rag build-pdf --dry-run \
    --chapters-table ssot_brochure.chapters \
    --template templates/chapter.template.tex \
    --lua-filter filters/force-fullwidth-hero.lua \
    --repo-root .

# Full build into ./generated/out/main.pdf:
trios-mcp-rag build-pdf \
    --chapters-table ssot.chapters \
    --template templates/chapter.template.tex \
    --lua-filter filters/force-fullwidth-hero.lua \
    --out-dir generated/out \
    --build-dir generated/build

# Smoke build with a small chapter cap:
trios-mcp-rag build-pdf --limit 3
```

All flags: `--dry-run` / `--check`, `--database-url-env`,
`--chapters-table`, `--out-dir`, `--build-dir`, `--template`,
`--lua-filter`, `--repo-root`, `--pdf-name`, `--limit`.

### MCP usage

```jsonc
// Dry-run from an MCP client:
{"name":"build_pdf","arguments":{"dry_run":true}}

// Generate the cover used by GOLDEN_CHAIN.pdf:
{"name":"build_cover","arguments":{
  "title": "GOLDEN CHAIN",
  "version": "v26",
  "image_path": "assets/covers/golden-chain-gpt2-cover.png",
  "build_dir": "generated/build",
  "compile": true
}}

// Full build:
{"name":"build_pdf","arguments":{
  "dry_run": false,
  "chapters_table": "ssot_brochure.chapters",
  "template": "templates/chapter.template.tex",
  "lua_filter": "filters/force-fullwidth-hero.lua",
  "out_dir": "generated/out",
  "build_dir": "generated/build"
}}

// Prepare a new SSOT chapter without writing to Railway:
{"name":"preview_chapter_insert","arguments":{
  "slug": "fm-13-depin-positioning",
  "kind": "frontmatter",
  "order_key": 65,
  "title": "Armored Provenance Layer for DePIN",
  "body_md": "# Armored Provenance Layer for DePIN\n\n..."
}}
```

The MCP tool defaults to `dry_run=true` so that an agent calling
`build_pdf` with no arguments only validates configuration.

### Testing

Unit tests cover markdown ordering, book-kind ordering, Markdown table
repair, secondary image recovery, identifier validation, CLI parsing,
and the dry-run path (no Postgres needed):

```bash
cargo test
```

Integration with a live Postgres requires `DATABASE_URL` (or
`RAILWAY_SSOT_URL`) pointing at a non-production SSOT mirror and the
`pandoc` + `tectonic` binaries on PATH.

## License

MIT OR Apache-2.0

## Links

- Main repo: [github.com/gHashTag/trios](https://github.com/gHashTag/trios)
- Trinity S³AI (formalization): [github.com/gHashTag/trinity-s3ai](https://github.com/gHashTag/trinity-s3ai)
- DOI: [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877)
- MCP specification: [modelcontextprotocol.io](https://modelcontextprotocol.io)
