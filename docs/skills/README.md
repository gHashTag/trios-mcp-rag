# Agent Skills — `docs/skills/`

Pre-packaged [Agent Skills](https://agentskills.io) that mirror this
repository's operating rules. They are designed to wake up any
agentskills-compatible host (Perplexity Computer, Claude Code with the
`skills` plugin, custom orchestrators) into the same operating posture
as `AGENTS.md` and `CLAUDE.md` require.

| File | Skill | When to load |
|------|-------|--------------|
| [`trios-mcp-rag.zip`](trios-mcp-rag.zip) | `trios-mcp-rag` (operating rules) | Always — for any task touching the GOLDEN BRIDGE / TRIOS S³AI compendium, the Railway/Postgres SSOT, the `build_pdf` pipeline, claim-status framing, or the Quickstart that connects this repo to Claude Code. |
| [`trios-research-canon.zip`](trios-research-canon.zip) | `trios-research-canon` (literature canon) | When you need to justify why a rule exists, draft a new chapter needing external citation anchoring, evaluate a claim's epistemic status, or defend a typography / build decision. Companion to the rules skill. |

## How to use

### Perplexity Computer

1. Open [Manage skills](https://www.perplexity.ai/computer/skills).
2. Upload both zips under "User skills".
3. The skill descriptions include trigger phrases; the platform will
   auto-load them when relevant tasks arrive.

### Other agentskills-compatible hosts

Unzip each archive and point your host at the resulting directory.
Each directory has a `SKILL.md` (YAML frontmatter + body) plus a
`references/` folder with normative reference files.

### Manual / from-scratch hosts

Read `SKILL.md` and the files in `references/` directly. They are
plain Markdown and follow the same content as `AGENTS.md` +
`docs/agent-rules/` + `docs/literature/`.

## Provenance

Both skills are derived from this repository. The zips here are
authoritative copies; the matching source folders are
`AGENTS.md` / `CLAUDE.md` / `docs/agent-rules/` (rules) and
`docs/literature/` (canon).
