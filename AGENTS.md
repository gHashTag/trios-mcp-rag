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
- [docs/agent-rules/07-golden-bridge-cover.md](docs/agent-rules/07-golden-bridge-cover.md)
  — `GOLDEN_BRIDGE_COVER_CANON` cover identity, the
  `TRIOS_PHD_CANONICAL_PIPELINE` recap, `DO_NOT_REBUILD_WITH_GENERIC_CODE`,
  `COVER_TEXT_RISK`, `SECRET_SAFETY`, and the `ASSET_HANDOFF` for using a
  selected cover artifact as the first page of the PDF.
- [docs/rag/trios-phd-canon.md](docs/rag/trios-phd-canon.md)
  — Canonical TRIOS PhD invariants for RAG / agent retrieval, including
  the `TRIOS_PHD_NO_IMAGE_TRAIN` rule and the accepted PDF QA baseline.
- [docs/qa/brochure-pdf-checklist.md](docs/qa/brochure-pdf-checklist.md)
  — Operational pre-publish checklist with the current accepted numeric
  baseline (150 A4 pages, zero anomaly hits, one image-heavy candidate).

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
9. **`GOLDEN_BRIDGE_COVER_CANON`** — the canonical cover is the
   user-selected **GPT Image 2 v1** style — visually the closest of
   the GPT Image 2 candidates to the previous TRIOS / *Flos Aureus*
   cover: black velvet / chalkboard background, deep antique gold
   calligraphic `Golden Bridge` title, white chalk Leonardo-style
   side formulas / diagrams, **three microchips labeled `PHI`,
   `EULER`, `GAMMA` connected by gold circuitry** as the central
   emblem, authors `Dmitrii Vasilev · Stergios Pellis · Scott Olsen`,
   and a bottom `TRINITY S3AI` ribbon. The canonical artifact names
   are `golden_bridge_gpt2_v1_canonical_6x9_print_cover.pdf` /
   `.png` and `golden_bridge_gpt2_v1_canonical_6x9_bleed_cover.png`
   — use them verbatim. Do **not** rebuild it with generic code
   (`DO_NOT_REBUILD_WITH_GENERIC_CODE`) — no CAD/vector UI cover, no
   ReportLab cover, no corporate brochure, no assembled flat layout —
   unless the user explicitly asks for that variant for the current
   build. The selected cover artifact enters the canonical pipeline as
   the first page via the `ASSET_HANDOFF` described in rule 07. GPT
   image text is acceptable as cover art but is **not** authoritative
   for publication metadata (`COVER_TEXT_RISK`). Cover-related assets
   and references must obey `SECRET_SAFETY` — no DSNs, tokens, or
   credentialed URLs in repo or PDF. See
   [docs/agent-rules/07-golden-bridge-cover.md](docs/agent-rules/07-golden-bridge-cover.md).

If you cannot satisfy a rule, stop and report. Do not silently relax it.
