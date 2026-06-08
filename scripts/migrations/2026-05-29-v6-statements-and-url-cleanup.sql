-- v6 fix-2: switch \textbf in fm-01f to markdown bold (so pandoc doesn't render literal backslash)
-- Also: aggressive trailing-punct strip for all autolinks

BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = '# Funding, Conflicts, Ethics & Data Availability {.unnumbered}

*A single page collecting the statements that journal style guides expect to see explicitly. The authors include them here so the referee does not have to look for them.*

**Funding statement.** This work received no external grant funding. All hardware costs for the three TinyTapeout SKY26b silicon submissions (TTSKY26b projects #4913, #4914, #4915) were borne by D. Vasilev as a private contribution to the TRIOS / Flos Aureus research programme. S. Pellis contributed prior-art derivations developed during independent research at the University of Ioannina; no Ioannina institutional funds were used for this volume. S. Olsen contributed the Tier-D φ-cosmology framing under a similarly independent capacity. The build pipeline (`trios-mcp-rag`) and its infrastructure (Railway Postgres) run on commercial cloud services paid for from the same private source.

**Conflict of interest statement.** D. Vasilev owns the TRIOS token referenced in the DePIN positioning chapter and is the maintainer of the [gHashTag](https://github.com/gHashTag) GitHub organisation that hosts the source code, the SSOT pipeline, and the silicon designs. The financial interest in a tokenomics outcome is disclosed here so the reader can weigh the DePIN-positioning chapter against this incentive. S. Pellis and S. Olsen declare no competing financial interest. No author received payment from any party in exchange for the conclusions reported in this volume.

**Ethics statement.** This work involves neither human-subject data nor animal-subject data. No IRB or ethics-board approval was required. The silicon designs were submitted to TinyTapeout under its standard open-source submission terms; no export-control or dual-use determination was triggered. The empirical claims concern published physical constants (CODATA 2018 / 2022) and replicate published symbolic-regression methodology. No personally identifiable information is contained in this volume.

**Data and code availability.** All Markdown sources, LaTeX templates, Lua filters, build tooling (Rust), Verilog HDL for the three TTSKY26b crowns, and the Coq mechanisation under `t27/proofs/trinity/` are publicly available at [gHashTag/trios-mcp-rag](https://github.com/gHashTag/trios-mcp-rag) and [gHashTag/trios-mcp](https://github.com/gHashTag/trios-mcp) under the Apache-2.0 licence. The structured SSOT (`ssot_brochure.chapters` on Railway Postgres) is mirrored as a TSV dump alongside each release. The PDF artefact carries DOI `10.5281/zenodo.19227877`; its SHA-256 is recorded in the build log on the publication branch. No proprietary or restricted data are referenced.

**Author contributions (CRediT).** **D. Vasilev** — conceptualisation, formal analysis, software, hardware (silicon), supervision, writing (original draft & review/editing), funding acquisition. **S. Pellis** — methodology (Pellis hierarchical expansion), formal analysis (α⁻¹ and μ derivations), validation, writing (review). **S. Olsen** — conceptualisation (Tier-D φ-cosmology framing), writing (Tier-D chapter), validation.

**ORCID iDs.** D. Vasilev: [0009-0008-4294-6159](https://orcid.org/0009-0008-4294-6159). S. Pellis: *ORCID not registered at the time of this freeze; the corresponding author will append it in an erratum if registered before peer review.* S. Olsen: *ORCID not registered at the time of this freeze.*

**Use of generative AI.** AI assistants (Claude Code, ChatGPT, and the project''s own `trios-mcp-rag` MCP server) were used for build-system engineering, draft prose, table normalisation, and QA scripts. All scientific claims, empirical fits, Coq proofs, and Verilog assertions are the responsibility of the named human authors. No AI system is listed as an author.

\clearpage
'
WHERE slug = 'fm-01f-statements';

-- Aggressive trailing-punct strip on autolinks across ALL chapters
-- Matches: any URL followed by '.' or ',' or ';' before whitespace/end → strip the punct
-- This is conservative: only autolink-style URLs (not markdown link [text](url))
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  '(https?://[A-Za-z0-9._/?&=~%#:+@!*-]+?)[\.,;]+(\s|$)',
  '\1\2', 'g')
WHERE body_md ~ 'https?://[A-Za-z0-9._/?&=~%#:+@!*-]+[\.,;]+(\s|$)';

COMMIT;
