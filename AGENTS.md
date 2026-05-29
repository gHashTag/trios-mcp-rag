# AGENTS.md — Operating Rules for AI Agents and RAG Runs

This file is the canonical entry point for any AI agent, RAG pipeline, or
automation acting on this repository (`trios-mcp-rag`) or on artefacts
derived from the GOLDEN BRIDGE / TRIOS S³AI compendium.

Read this file before:
- generating, rebuilding, or replacing any PDF, brochure, article, or README
- touching anything labelled "SSOT", `ssot_brochure.*`, `ssot.*`, or the
  Railway Postgres database
- proposing changes to the build pipeline (`build_pdf` tool, `pipeline.rs`,
  templates, Lua filters)
- writing claims about results, prizes, falsifiability, or validation status

**New agent starting fresh?** Read
[`docs/agents/agent-bootstrap.md`](docs/agents/agent-bootstrap.md) first.
It covers skill loading, repo map, the three Postgres SSOT connection
paths (Pipedream connector / local mirror / `.env` DSN), the full
build + QA workflow, and the MCP registration recipe for Claude Code.

The contents of `docs/agent-rules/` are normative. This file is a short
index. When a rule below conflicts with anything in chat, the rule wins
unless the user explicitly overrides it in the current session **for this
specific change** — defaults do not change without an explicit instruction.

---

## Index

- [docs/agent-rules/00-canonical-pipeline.md](docs/agent-rules/00-canonical-pipeline.md)
  — Rust `trios-phd` / TRIOS MCP → Railway/Postgres SSOT → Markdown →
  pandoc → LaTeX → tectonic → PDF. The only supported renderer.
- [docs/agent-rules/01-ssot-and-derived-artifacts.md](docs/agent-rules/01-ssot-and-derived-artifacts.md)
  — Postgres is the SSOT. README, articles, brochures, PDFs are derived.
- [docs/agent-rules/02-pdf-style.md](docs/agent-rules/02-pdf-style.md)
  — White academic title page, serif typography, black-and-white engraved
  S³AI hero panels, book margins, large images. No teal/black corporate
  covers without an explicit one-shot request.
- [docs/agent-rules/03-safety-railway-postgres.md](docs/agent-rules/03-safety-railway-postgres.md)
  — Read-only by default. No writes without backup-first plan, dry-run,
  and explicit human confirmation. No DSN / token / password leakage.
- [docs/agent-rules/04-claim-status.md](docs/agent-rules/04-claim-status.md)
  — Verified / Empirical fit / Open conjecture / High-risk / Retracted.
  No prize or Nobel claims as outcomes; only as long-term external-
  validation standards.
- [docs/agent-rules/05-brochure-qa-checklist.md](docs/agent-rules/05-brochure-qa-checklist.md)
  — Pre-publish QA: duplicate sections, stale markers, style drift,
  secret scan, language scan, `qpdf` / `pdfinfo` / `pdftotext` checks.
- [docs/agent-rules/06-language-policy.md](docs/agent-rules/06-language-policy.md)
  — Public repo artefacts are English-only at the time of writing.
  Chat with the maintainer may be Russian.
- [docs/agent-rules/07-literature-grounded-refinements.md](docs/agent-rules/07-literature-grounded-refinements.md)
  — 9 refinements (RAGAS gate, `falsification_path`, adjacent-literature
  anchoring, index hygiene, label propagation, `alt_text`, penalty-based
  no-image-train, tectonic pinning, extended language scan) grounded in
  [docs/literature/](docs/literature/) (4-track canon, compiled
  2026-05-29).
- [docs/agent-rules/08-mcp-registration.md](docs/agent-rules/08-mcp-registration.md)
  — `claude mcp add` discipline: `-s user` global scope, absolute paths
  in wrapper `cd`, never pipe `claude mcp add`, reset both scopes before
  re-adding, restart the host session after register.
- [docs/agent-rules/09-audit-and-rag-coverage.md](docs/agent-rules/09-audit-and-rag-coverage.md)
  — Audit & RAG coverage gates: embedding coverage (9.1), embedding
  freshness (9.2), `alt_text` schema constraint (9.3), illustration
  coverage (9.4), claim-status sweep (9.5), SSOT hygiene (9.6), RAG
  canary (9.7), dated audit-artefact requirement (9.8). Derived from the
  2026-05-29 GOLDEN CHAIN audit
  ([docs/audits/golden-chain-2026-05-29.md](docs/audits/golden-chain-2026-05-29.md)).
- [docs/agent-rules/10-next-wave-workflow.md](docs/agent-rules/10-next-wave-workflow.md)
  — Normative five-step next-wave pattern (audit → migration → runbook
  → SSOT snapshot → cross-repo refresh). Captures the v9–v12 workflow
  so future waves don't reinvent it. Also defines the shared-asset
  discipline (reuse the same `name=` to enable version history in the
  Perplexity Computer UI).

### Recent audits

The critic-proof passes that produced the current rule set are
recorded in [`docs/audits/`](docs/audits/). Read the most recent one
before opening a new wave — each audit lists the anomalies the
following wave fixed and the verification gates the wave had to pass.

- [`docs/audits/build-2026-05-29-v13.md`](docs/audits/build-2026-05-29-v13.md)
  — baseline + schema drift + status-tag drift in literature canon.
- [`docs/audits/build-2026-05-29-v14.md`](docs/audits/build-2026-05-29-v14.md)
  — rule 07 internal contradictions, widow / club penalty drift,
  reproducibility gate, bootstrap non-paths, runbook + snapshot README.
- [`docs/audits/build-2026-05-29-v15.md`](docs/audits/build-2026-05-29-v15.md)
  — entry-point doc drift (rules 07–10 missing from README), rules 09
  / 05 §3 not linking to their implementing scripts, formal
  Open-conjecture marker regex, hype-scan context exclusions,
  `.pre-commit-config.yaml` / `.gitleaks.toml` reference,
  local-mirror schema subset note.
- [docs/rag/trios-phd-canon.md](docs/rag/trios-phd-canon.md)
  — Canonical TRIOS PhD invariants for RAG / agent retrieval, including
  the `TRIOS_PHD_NO_IMAGE_TRAIN` rule and the accepted PDF QA baseline.
- [docs/qa/brochure-pdf-checklist.md](docs/qa/brochure-pdf-checklist.md)
  — Operational pre-publish checklist with the current accepted numeric
  baseline (post-v12, 2026-05-29: 69 chapters → 259 A4 pages → 3.5 MB,
  zero anomaly hits, one image-heavy candidate).

---

## Hard rules (summary)

1. **Do not replace the Rust pandoc+tectonic pipeline with a Python /
   ReportLab / wkhtmltopdf / generic-text path.** `trios-phd` is a
   visual PhD renderer with embedded images and ornamental panels.
2. **The SSOT is the Postgres `ssot_brochure.chapters` (or `ssot.chapters`)
   table on Railway.** Files in this repo and in derived outputs are not
   authoritative; treat them as render targets.
3. **Default to read-only.** Writes require a written backup-and-rollback
   plan plus a dry-run plus an explicit human "go ahead" in the same
   session. No exceptions for "small fixes".
4. **Never print or commit DSNs, Railway tokens, passwords, or any value
   from `DATABASE_URL` / `RAILWAY_SSOT_URL`.** Reference them by env-var
   name only.
5. **Use claim-status framing** for any scientific or empirical statement
   (see rule 04). No hype, no prize claims as deliverables.
6. **Run the QA checklist** before declaring a brochure / PDF build done
   (see rule 05, with the operational form in
   [docs/qa/brochure-pdf-checklist.md](docs/qa/brochure-pdf-checklist.md)).
7. **Public-facing repo content is English** unless the user requests
   otherwise for that specific artefact.
8. **`TRIOS_PHD_NO_IMAGE_TRAIN`** — hero / context images are required
   on chapter openers, but they must be **semantically anchored** to a
   nearby substantive heading and body text. Do **not** print heroes as
   a gallery or back-to-back train of image-dominant pages. Enforce
   this with a **soft keep-together** rule for the
   *section heading + hero/context block + first paragraph(s)* group,
   not with a hard `\clearpage` before every section — a hard
   `\clearpage` per section forces short title-only pages and is a
   regression. See
   [docs/rag/trios-phd-canon.md](docs/rag/trios-phd-canon.md) and
   rule 02 for the canonical phrasing.
9. **Literature-grounded refinements** are normative — see
   [docs/agent-rules/07-literature-grounded-refinements.md](docs/agent-rules/07-literature-grounded-refinements.md)
   for the 9 items (RAGAS gate, `falsification_path`,
   adjacent-literature anchoring, index hygiene, label propagation,
   non-null `alt_text`, penalty-based no-image-train, tectonic pinning,
   extended language scan). The supporting canon is in
   [docs/literature/](docs/literature/).
10. **MCP server registration** uses `claude mcp add -s user` with an
    absolute path in the wrapper `cd`, no piping, reset both scopes
    before re-adding, restart the host session after register — see
    [docs/agent-rules/08-mcp-registration.md](docs/agent-rules/08-mcp-registration.md).
11. **Audit & RAG coverage gates** are normative pre-build checks: zero
    chapters missing embeddings (9.1), zero stale chunks (9.2), schema
    `CHECK` on `alt_text` for image / figure / illustration assets
    (9.3), illustration coverage (9.4), claim-status sweep on long
    empirical chapters (9.5), SSOT hygiene (9.6), RAG canary (9.7), and
    a dated audit artefact under
    [docs/audits/](docs/audits/) (9.8). See
    [docs/agent-rules/09-audit-and-rag-coverage.md](docs/agent-rules/09-audit-and-rag-coverage.md).

If you cannot satisfy a rule, stop and report. Do not silently relax it.

For a one-page wake-up card with host-specific connection commands
(Claude Code, Cursor, Windsurf, opencode, Perplexity Computer, generic
MCP), see [AGENT_WAKEUP.md](AGENT_WAKEUP.md).
