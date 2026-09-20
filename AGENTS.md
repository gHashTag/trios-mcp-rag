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

If you cannot satisfy a rule, stop and report. Do not silently relax it.

## Own language first

When this project publishes something about itself, it publishes in **this
project's own language and format** -- not translated into somebody else's.

Owner's rule, 2026-09-20: stop writing in other people's languages, we have our
own.

This bites on any file whose only reason to exist is that an outside tool
expects that shape: `llms.txt`, `agents.json`, `ai.txt`, `.well-known/*.json`,
A2A agent cards, `ai-plugin` manifests, OpenAPI stubs, JSON-LD blocks, a README
that restates a spec. The reflex is to write four of them in four foreign
formats, and the reflex is wrong: a project whose claim is "here is a language
worth writing" and which then describes itself in three of other people's
formats has published three documents that are not true of it.

**The move:** find the address the outside world already fetches, then serve our
own language at it. `/llms.txt` at t27.ai **is** a t27 module -- `llms.txt`
requires nothing but text, and every prose line of a `.t27` file is a `;`
comment, so it stays readable to anything that cannot compile it.

**Three qualifications, so the rule stays honest:**

- A format a resolver genuinely parses -- a sitemap, `package.json`, a lockfile
  -- is machinery, not a description. **Generate** it from our own source; never
  hand-write it into a second home for the truth.
- Code against someone else's API uses their types. Prose for a human who has
  never heard of the project uses that human's language.
- If a format demands a claim we cannot back, **publish nothing**. An A2A card
  with no A2A server behind it is a false claim, and a missing file is more
  honest than a lying one.

The test: *is this file the project speaking about itself?* If yes, it speaks
our language. If it is plumbing, it speaks the plumbing's.

**Worked example, compiler-checked rather than asserted:** in `gHashTag/trinity`,
`apps/website/public/t27/files/specs/catalog/onboarding.t27` generates
`/llms.txt` and `/agents.t27` byte-identically, gated in CI as
`check:onboarding`. The generator evaluates the spec's own `test` blocks --
`typecheck.ok` stays true for `assert 1 > 2`, so a compiler saying "this parses"
is not a compiler saying "this is true" -- and re-compiles the rendered document
before writing it.

**The full rule lives in exactly one place: the `own-language-first` skill**
(`~/.claude/skills/own-language-first/SKILL.md`). It carries the consent gate for
documents addressed to other people's agents, the six negative controls, and the
`;`-alone-on-a-line trap that silently discards a `module` declaration. This
section is a pointer, not a copy -- the recorded defect in this codebase family
is the hand-copied rule that only two of its three homes knew about.
