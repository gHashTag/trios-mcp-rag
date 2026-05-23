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
- Preserve the `GOLDEN_BRIDGE_COVER_CANON` (black velvet + antique
  gold calligraphic title + white chalk da-Vinci formulas + three
  microchips + `TRINITY S3AI` bottom ribbon). Do not regenerate the
  cover with generic code (ReportLab, CAD/vector UI, corporate
  brochure, assembled flat layout) without an explicit one-shot
  request. See
  [docs/agent-rules/07-golden-bridge-cover.md](docs/agent-rules/07-golden-bridge-cover.md).

See:

- [AGENTS.md](AGENTS.md) — full index of rules
- [docs/agent-rules/](docs/agent-rules/) — normative rule files

When a chat instruction conflicts with these rules, the rules win unless
the user explicitly overrides them for the specific change in the same
session.
