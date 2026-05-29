# CLAUDE.md

This file is the entry point for Claude Code sessions on this repo. Read
`AGENTS.md` first — it is the canonical rule set and applies to all AI
agents (Claude Code, Cursor, opencode, Windsurf, RAG runs, automation).

Quick summary of the hard rules:

- The TRIOS PhD pipeline (`trios-phd` → Railway/Postgres SSOT → Markdown
  → pandoc → LaTeX → tectonic → PDF) is the only supported render path.
  Do not substitute ReportLab / WeasyPrint / generic PDF tools.
- Postgres `ssot_brochure.chapters` is the SSOT. README, brochure, PDF,
  and articles are derived; don't edit them as if they were authoritative.
- Read-only by default. Writes require backup-first plan + dry-run +
  explicit in-session confirmation. Never log or commit DSNs / tokens.
- Use claim-status framing (Verified / Empirical fit / Open conjecture /
  High-risk / Retracted). No prize claims as deliverables.
- Public repo content is English. Chat with the maintainer can be Russian.
- Run the brochure QA checklist before declaring a build done.

See:

- [AGENT_WAKEUP.md](AGENT_WAKEUP.md) — one-page wake-up card (rules +
  host-specific connection commands + GOLDEN CHAIN PDF build steps)
- [AGENTS.md](AGENTS.md) — full index of rules
- [docs/agent-rules/](docs/agent-rules/) — normative rule files,
  including
  [`07-literature-grounded-refinements.md`](docs/agent-rules/07-literature-grounded-refinements.md),
  [`08-mcp-registration.md`](docs/agent-rules/08-mcp-registration.md),
  and
  [`09-audit-and-rag-coverage.md`](docs/agent-rules/09-audit-and-rag-coverage.md)
  (the GOLDEN CHAIN audit gates).
- [docs/audits/](docs/audits/) — dated audit artefacts driven by
  rule 09.8 (`golden-chain-<YYYY-MM-DD>.md`).
- [docs/literature/](docs/literature/) — 4-track research canon backing
  the refinements

When a chat instruction conflicts with these rules, the rules win unless
the user explicitly overrides them for the specific change in the same
session.
