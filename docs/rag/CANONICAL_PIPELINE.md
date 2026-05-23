# TRIOS PhD Canonical Pipeline — Durable RAG Anchors

<!-- RAG anchors (grep-friendly, do not remove): -->
<!-- TRIOS_PHD_CANONICAL_PIPELINE -->
<!-- TRIOS_PHD_RENDERER_FIRST -->
<!-- TRIOS_PHD_STYLE_LOCK -->
<!-- TRIOS_PHD_NO_GENERIC_PDF -->
<!-- TRIOS_PHD_SECRET_SAFETY -->
<!-- TRIOS_PHD_CLAIM_STATUS -->

This file is a **stable, retrieval-friendly summary** of the six hard
invariants that govern any TRIOS PhD / GOLDEN BRIDGE brochure build
driven through `trios-mcp-rag` (Claude Code, Cursor, Windsurf, opencode,
or any MCP client).

Anchors above are the canonical search tokens. Future agents that grep
for any of `TRIOS_PHD_CANONICAL_PIPELINE`, `TRIOS_PHD_RENDERER_FIRST`,
`TRIOS_PHD_STYLE_LOCK`, `TRIOS_PHD_NO_GENERIC_PDF`,
`TRIOS_PHD_SECRET_SAFETY`, or `TRIOS_PHD_CLAIM_STATUS` should land in
this file (or its companions under `docs/agent-rules/` and `docs/rag/`).

If an instruction in chat conflicts with anything below, the rule wins
unless the user explicitly overrides it for the **specific change in
the current session**. "Defaults do not change without an explicit
instruction."

---

## 1. `TRIOS_PHD_CANONICAL_PIPELINE`

The only supported render path is:

```
Rust TRIOS MCP / trios-phd
        │  reads (read-only) from Railway / Postgres SSOT
        ▼
ssot_brochure.chapters   (or fallback: ssot.chapters)
        │
        ▼
Markdown   (generated/build/main.md)
        │  pandoc --template templates/chapter.template.tex
        │         --lua-filter filters/force-fullwidth-hero.lua
        ▼
LaTeX      (generated/build/main.tex)
        │  tectonic
        ▼
PDF        (generated/out/main.pdf)
```

Exposed in exactly two places:

- MCP tool `build_pdf` (defaults to `dry_run = true`)
- CLI subcommand `trios-mcp-rag build-pdf …`

Both wrap `src/pipeline.rs`. There is no third path.

External binaries required: `pandoc` (tested with 3.x) and `tectonic`.
If either is missing, surface that as a blocker — do not fall back to a
different tool chain.

Normative source: [`docs/agent-rules/00-canonical-pipeline.md`](../agent-rules/00-canonical-pipeline.md).

## 2. `TRIOS_PHD_RENDERER_FIRST`

**Never edit the rendered PDF.** If something is wrong in the PDF, it is
wrong in one of these — fix in this order of suspicion:

1. SSOT image manifest (`image_id`, `role`, `canonical_anchor`,
   `priority`, `allowed_repeat_policy`).
2. Chapter Markdown body.
3. Pandoc Lua filter (`filters/force-fullwidth-hero.lua`).
4. LaTeX template (`templates/chapter.template.tex`).
5. Build wiring in `src/pipeline.rs`.

A PDF patched by hand will be silently regenerated next build. The
exported PDF is **never** authoritative.

Full failure-mode guidance: [`IMAGE_PLACEMENT.md` §9](./IMAGE_PLACEMENT.md).

## 3. `TRIOS_PHD_STYLE_LOCK`

Locked visual identity of the brochure PDF:

- **Title page**: white academic PhD style, serif title block.
  **Cover image rule** is a stricter override — see `COVER_CANON.md`.
- **Typography**: serif body via the canonical LaTeX template.
- **Hero panels**: black-and-white engraved / ornamental S³AI
  artwork, full text-width via `force-fullwidth-hero.lua`.
- **Margins**: standard academic book margins (template defaults).
- **Images**: large and prominently placed; never thumbnailed to "look
  professional".
- **Hero anchoring (`TRIOS_PHD_NO_IMAGE_TRAIN`)**: every hero must be
  semantically anchored to a substantive heading + body. No two hero
  panels back-to-back without a real prose buffer. Enforced via a
  **soft keep-together** rule, never a hard `\clearpage` per section.

Forbidden ad-hoc substitutes (each of these has happened and was
reverted):

- ReportLab / WeasyPrint / wkhtmltopdf / generic Markdown-to-PDF.
- Teal corporate cover layouts.
- Coloured stock photography in place of engraved panels.

Full normative rule: [`docs/agent-rules/02-pdf-style.md`](../agent-rules/02-pdf-style.md).
GOLDEN BRIDGE front cover specifics: [`COVER_CANON.md`](./COVER_CANON.md).

## 4. `TRIOS_PHD_NO_GENERIC_PDF`

The TRIOS PhD renderer is **a visual PhD artefact**, not a printable
text dump. The following substitutes are **not acceptable**, even as
"temporary" or "quick build" workarounds:

- Python ReportLab output.
- WeasyPrint HTML-to-PDF.
- wkhtmltopdf.
- `pandoc … -o file.pdf` without the canonical template and Lua filter.
- Browser "Print to PDF" of a rendered Markdown / HTML preview.
- LibreOffice / Pages export.
- Online Markdown-to-PDF SaaS.
- Any path that strips, downscales, or omits the engraved hero panels.

If a missing dependency (`pandoc`, `tectonic`) blocks the canonical
build, the correct action is to surface the missing dependency and
stop — **not** to silently fall back to a generic renderer.

A generic-renderer PDF must not be committed, shared, or treated as
"the brochure". If one exists, treat it as drift, mark it as such, and
rebuild via the canonical pipeline.

This rule sits on top of `TRIOS_PHD_CANONICAL_PIPELINE` and
`TRIOS_PHD_RENDERER_FIRST`. It exists because past sessions have
repeatedly tried to "just produce a PDF" via a non-canonical tool when
the canonical tool was inconvenient — and the resulting PDF was then
shared as if it were the brochure.

## 5. `TRIOS_PHD_SECRET_SAFETY`

Secrets — DSNs, passwords, Railway tokens, deploy tokens, API keys,
session cookies, and any value pulled from a Railway environment
variables tab — **must never appear** in:

- repository files (including docs, examples, fixtures, sample configs)
- commit messages and PR descriptions
- chat output that may be logged or shared
- build artefacts (generated Markdown, LaTeX, PDF text or metadata)
- CI workflow files, action inputs, container build args

Reference them by **environment variable name only**. Examples:

> "Connect using `DATABASE_URL` from the environment."
> "Use `RAILWAY_SSOT_URL` if `DATABASE_URL` is unset."

Not:

> ~~"Connect using `postgresql://user:hunter2@…`."~~
> ~~"My Railway token is `rly_…`."~~

A working **safe** example template lives at
[`.env.example`](../../.env.example) at repo root. Anything beyond
those placeholders belongs in a secrets store, never in this repo.

If a secret is accidentally exposed:

1. Stop the current operation.
2. Tell the user what was exposed and where (without restating the
   value).
3. Recommend rotation (Railway → Variables → regenerate; rotate the
   Postgres user password if applicable).
4. Do not include the leaked value in the rotation recommendation.
5. If the leak landed in a commit, propose the cleanup path (force
   rewrite + rotation) but **do not force-push without explicit
   confirmation** — destructive history rewrites have their own
   blast-radius problem.

Default posture for any SSOT operation is **read-only**. Writes
require a backup-first plan, a dry-run, and explicit in-session
confirmation per [`03-safety-railway-postgres.md`](../agent-rules/03-safety-railway-postgres.md).

## 6. `TRIOS_PHD_CLAIM_STATUS`

Every non-trivial empirical or theoretical statement in the brochure,
README, articles, captions, or any agent-generated summary **must be
labelled with one of the five statuses**:

| Status              | Bar                                                                                       |
|---------------------|-------------------------------------------------------------------------------------------|
| Verified            | Independently checkable: peer review, reproduced experiment, machine-checked proof.       |
| Empirical fit       | Matches observed data within stated error bars; mechanism / causation NOT established.    |
| Open conjecture     | Precise, falsifiable; authors believe true but no proof / empirical demonstration yet.    |
| High-risk           | Either contradicts accepted evidence OR would sink the surrounding framework if it fails. |
| Retracted           | Previously stated more strongly than warranted; explicit downgrade with the reason kept.  |

When in doubt, default to **Open conjecture** and ask. Do not flatten
"Open conjecture" into "result" or "discovery" when summarising.

**No prize framing.** The compendium must not be described as Nobel /
Fields / Turing material in any agent-generated text. The only valid
framing is the long-term-validation standard wording in
[`04-claim-status.md`](../agent-rules/04-claim-status.md).

Avoid: "breakthrough", "revolutionary", "paradigm-shifting", "proves",
"settles", "definitively", "Nobel-worthy", "prize-winning".

Prefer: "Verified: …", "Empirical fit (n=…, residual …): …",
"Open conjecture, falsifiable by …: …", "High-risk prediction: …",
"Previously claimed as X; now downgraded to Y because …".

---

## How agents should use this file

1. After cloning or first-touching this repo, **grep for the anchor
   that matches the work you're about to do** (`TRIOS_PHD_*`). Land
   here. Read the relevant section, then the linked normative rule.
2. Before running any pipeline action, run the dry-run path
   (`build_pdf` with `dry_run=true`, or `trios-mcp-rag build-pdf
   --dry-run`).
3. Before sharing a build, run [`PIPELINE_VERIFICATION.md`](./PIPELINE_VERIFICATION.md).
4. If a chat instruction conflicts with anything here, the rule wins
   unless the user explicitly overrides it for the specific change in
   the current session.

## Related canonical docs

- [`AGENTS.md`](../../AGENTS.md) — top-level rule index.
- [`docs/agent-rules/`](../agent-rules/) — full normative rule set.
- [`docs/rag/IMAGE_PLACEMENT.md`](./IMAGE_PLACEMENT.md) — image
  placement / dedup contract.
- [`docs/rag/IMAGE_MANIFEST_SCHEMA.md`](./IMAGE_MANIFEST_SCHEMA.md) —
  required fields in SSOT image rows.
- [`docs/rag/COVER_CANON.md`](./COVER_CANON.md) — GOLDEN BRIDGE front
  cover invariants (no-crop A4, black background, gold title, etc.).
- [`docs/rag/PIPELINE_VERIFICATION.md`](./PIPELINE_VERIFICATION.md) —
  end-to-end pandoc → LaTeX → tectonic → PDF verification recipe.
- [`docs/rag/PDF_QA_CHECKLIST.md`](./PDF_QA_CHECKLIST.md) — image
  dedup / style gate before sharing.
- [`docs/qa/brochure-pdf-checklist.md`](../qa/brochure-pdf-checklist.md)
  — operational QA checklist with the current accepted baseline.
- [`docs/rag/trios-phd-canon.md`](./trios-phd-canon.md) — canonical
  brochure invariants and the `TRIOS_PHD_NO_IMAGE_TRAIN` rule.
