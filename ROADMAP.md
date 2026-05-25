# TRIOS MCP-RAG Roadmap

This roadmap keeps the repository aligned with the canonical renderer:

```text
Railway/Postgres SSOT -> Markdown -> pandoc -> LaTeX -> tectonic -> PDF
```

## Phase 0 — Safety and reproducibility

- Keep Railway/Postgres read-only by default.
- Remove DSN values from docs, logs, command examples, and generated
  artifacts; refer to `DATABASE_URL` / `RAILWAY_SSOT_URL` by name only.
- Keep `build_pdf` dry-run by default in MCP.
- Keep every generated PDF behind `qpdf`, `pdfinfo`, text-layer,
  language, secret, duplicate, and image-train checks.

## Phase 1 — MCP tool completeness

- `build_pdf`: canonical SSOT to PDF renderer.
- `build_book`: book-mode wrapper with TOC and chapter-level structure.
- `build_cover`: GPT-2 / Leonardo chalk architect cover generator.
- `preview_chapter_update`: dry-run SQL plan for replacing one body.
- `preview_chapter_insert`: dry-run SQL plan for adding one chapter.
- `backup_ssot`: explicit backup table creation, only after confirmation.
- `get_claim_status`, `list_claims`, and `get_honest_counters`: RAG
  claim-discipline helpers.

## Phase 2 — Layout stabilization

- Normalize Markdown tables before pandoc so formula cells do not break
  column boundaries.
- Keep long tables small, link-safe, and full-width.
- Keep chapter heroes large but semantically anchored.
- Enforce `TRIOS_PHD_NO_IMAGE_TRAIN` with soft keep-together behavior,
  not hard section-level page breaks.
- Track secondary/orphan images from SSOT assets, but render them only
  after they receive semantic anchors in the image manifest.

## Phase 3 — SSOT content update

Prepared but not executed:

- add a DePIN positioning chapter,
- update or create the Vasilev/Pellis constants article,
- attach chain-of-custody competitor research as supporting RAG context.

Execution requires the Railway write gate:

1. backup-first plan,
2. dry-run,
3. exact row scope,
4. explicit in-session confirmation,
5. post-write verification and rebuild.

## Phase 4 — Chain-of-custody proof productization

Use the positioning in `docs/CHAIN_OF_CUSTODY_COMPETITORS.md`:

- define the TRIOS custody packet,
- map packet fields to GS1 EPCIS, W3C Verifiable Credentials, and IETF
  RATS concepts,
- define adapter stubs for IoTeX W3bstream, peaq verify, Chainlink /
  oracle flows, and enterprise traceability systems,
- keep `0x47C0` framed as a hardware provenance witness, not as proof
  of physical truth.

## Phase 5 — Validation pilots

Best first pilots:

- battery / critical-minerals handoff,
- pharma cold-chain release,
- EV charging / energy metering,
- machine-service proof,
- DePIN validator edge data courier.

Each pilot should publish:

- threat model,
- custody packet schema,
- verifier policy,
- replay/tamper tests,
- false-positive / false-negative analysis,
- exact claim-status table.
