# RAG and PDF Pipeline Test Plan

This is the operational test plan for the MCP-RAG path:

```text
Railway/Postgres SSOT -> Markdown -> pandoc -> LaTeX -> tectonic -> PDF
```

It complements `docs/rag/PDF_QA_CHECKLIST.md` and the agent rules in
`docs/agent-rules/`.

## 1. Local unit tests

Run:

```bash
cargo test
```

Required coverage:

- chapter ordering by logical book kind and `order_key`,
- Markdown table repair for formula cells containing `|...|`,
- spacing of dense Unicode formula cells before pandoc,
- table-name validation before SQL interpolation,
- dry-run build checks without a live database,
- secondary image recovery by brochure image index.

## 2. MCP smoke tests

The server must expose the build and safety tools:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"build_pdf","arguments":{"dry_run":true}}}' \
  | cargo run --quiet
```

Expected:

- `build_pdf` is present and defaults to dry-run,
- `build_book` is present and forces book mode,
- `build_cover` is present for the Leonardo chalk cover,
- `preview_chapter_update` and `preview_chapter_insert` are dry-run only,
- `backup_ssot` is explicit and never runs unless `confirm=true`.

If `DATABASE_URL` / `RAILWAY_SSOT_URL` is absent, the dry-run must
report that fact by environment variable name only and must not print a
DSN value.

## 3. RAG quality checks

When a live SSOT mirror is available, run:

```json
{"name":"list_chapters","arguments":{}}
{"name":"forbidden_audit","arguments":{}}
{"name":"list_claims","arguments":{}}
{"name":"get_honest_counters","arguments":{}}
```

Pass conditions:

- no forbidden stale terms in public chapters,
- every scientific or empirical statement is framed as `Verified`,
  `Empirical fit`, `Open conjecture`, `High-risk`, or `Retracted`,
- trinity-s3ai counters match the current audited snapshot,
- no Russian text appears in public English SSOT rows unless a specific
  bilingual artifact was requested.

## 4. Full PDF build gate

Only run a full build when the database environment is intentionally set:

```bash
trios-mcp-rag build-pdf \
  --chapters-table ssot_brochure.chapters \
  --template templates/chapter.template.tex \
  --lua-filter filters/force-fullwidth-hero.lua \
  --out-dir generated/out \
  --build-dir generated/build
```

Then run:

```bash
qpdf --check generated/out/main.pdf
pdfinfo generated/out/main.pdf | head
pdftotext generated/out/main.pdf - | \
  grep -nE 'TODO|FIXME|XXX|TKTK|LOREM|<<|>>|\[draft\]|\[wip\]|<placeholder>|YYYY|<DATE>' \
  || echo 'stale-marker scan: clean'
pdftotext generated/out/main.pdf - | \
  grep -nE '\\frac|\\sum|\\int|\\sqrt|\$\$|\\\\(left|right)\b' \
  || echo 'math-anomaly scan: clean'
```

Complete the full checklist in `docs/qa/brochure-pdf-checklist.md`
before publishing or sharing a generated PDF.

## 5. Railway write gate

The default posture is read-only. A chapter update or insert requires,
in this order:

1. backup-first plan,
2. dry-run via `preview_chapter_update` or `preview_chapter_insert`,
3. exact row scope,
4. explicit in-session human confirmation,
5. reversible execution and post-write verification.

Do not write to Railway from a PDF build job.
