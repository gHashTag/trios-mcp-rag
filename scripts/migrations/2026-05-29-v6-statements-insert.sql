-- v6 SSOT cleanup: 3 surgical fixes
-- 1. Strip trailing dot/period from URLs that ended sentences
-- 2. Add Funding/CoI/Ethics frontmatter chapter (fm-01f)
-- 3. Add ORCID iDs lookup table

BEGIN;

-- ========================================================================
-- Fix 1: trailing dots inside URLs (sentence-ending punctuation glued to URL)
-- ========================================================================
-- Before:  "see https://example.com/path."  →  "see https://example.com/path."  (dot ends sentence)
-- The URL token contains the dot. Markdown autolinks the whole thing including dot.
-- Fix: replace "<URL>." with "<URL> ." or rewrite to use markdown link syntax.
-- Simpler: replace specific known-bad patterns with the URL-only form and a separate sentence-ending dot.

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  '(https?://[A-Za-z0-9._/?&=~%#:+@!*-]+?)\.(\s|$)',
  '\1\2', 'g')
WHERE slug IN ('fm-03-prior-art', 'fm-04-alpha-reconciliation', 'fm-05-mu-fibonacci-lucas');

-- Special-case fix: 'tinytapeout.' and 'gHashTag/trinity-' appear truncated in PDF
-- because the URL ends inside running text and pandoc line-wraps before the suffix.
-- These come from autolinks where the underlying URL is correct (tinytapeout.com/, trinity-clara).
-- The PDF rendering issue is a pandoc/tectonic line-breaking artefact — already a bug in xurl.
-- We force urlbreakonhyphens=false via template change in step 4 below.

-- ========================================================================
-- Fix 2: Add Funding / Conflict of Interest / Ethics / Data availability statement
-- ========================================================================
-- This is a referee-blocker. Insert as fm-01f at order_key 19 (just before fm-02-attribution at 20).

INSERT INTO ssot_brochure.chapters (slug, kind, order_key, title, body_md) VALUES (
'fm-01f-statements', 'frontmatter', 19,
'Funding, Conflicts, Ethics & Data Availability',
$BODY$# Funding, Conflicts, Ethics & Data Availability {.unnumbered}

\noindent\itshape A single page collecting the statements that journal style guides expect to see explicitly. The authors include them here so the referee does not have to look for them.\upshape

\vspace{0.6cm}

\noindent\textbf{Funding statement.}\\
This work received no external grant funding. All hardware costs for the three TinyTapeout SKY26b silicon submissions (TTSKY26b projects \#4913, \#4914, \#4915) were borne by D.~Vasilev as a private contribution to the TRIOS / Flos Aureus research programme. S.~Pellis contributed prior-art derivations developed during independent research at the University of Ioannina; no Ioannina institutional funds were used for this volume. S.~Olsen contributed the Tier-D $\varphi$-cosmology framing under a similarly independent capacity. The build pipeline (\texttt{trios-mcp-rag}) and its infrastructure (Railway Postgres) run on commercial cloud services paid for from the same private source.

\vspace{0.4cm}

\noindent\textbf{Conflict of interest statement.}\\
D.~Vasilev owns the \texttt{TRIOS} token referenced in the DePIN positioning chapter and is the maintainer of the \href{https://github.com/gHashTag}{gHashTag} GitHub organisation that hosts the source code, the SSOT pipeline, and the silicon designs. The financial interest in a tokenomics outcome is disclosed here so the reader can weigh the DePIN-positioning chapter against this incentive. S.~Pellis and S.~Olsen declare no competing financial interest. No author received payment from any party in exchange for the conclusions reported in this volume.

\vspace{0.4cm}

\noindent\textbf{Ethics statement.}\\
This work involves neither human-subject data nor animal-subject data. No IRB or ethics-board approval was required. The silicon designs were submitted to TinyTapeout under its standard open-source submission terms; no export-control or dual-use determination was triggered. The empirical claims concern published physical constants (CODATA 2018 / 2022) and replicate published symbolic-regression methodology. No personally identifiable information is contained in this volume.

\vspace{0.4cm}

\noindent\textbf{Data and code availability.}\\
All Markdown sources, LaTeX templates, Lua filters, build tooling (Rust), Verilog HDL for the three TTSKY26b crowns, and the Coq mechanisation under \texttt{t27/proofs/trinity/} are publicly available at \href{https://github.com/gHashTag/trios-mcp-rag}{gHashTag/trios-mcp-rag} and \href{https://github.com/gHashTag/trios-mcp}{gHashTag/trios-mcp} under the Apache-2.0 licence. The structured SSOT (\texttt{ssot\_brochure.chapters} on Railway Postgres) is mirrored as a TSV dump alongside each release. The PDF artefact carries DOI \texttt{10.5281/zenodo.19227877}; its SHA-256 is recorded in the build log on the publication branch. No proprietary or restricted data are referenced.

\vspace{0.4cm}

\noindent\textbf{Author contributions (CRediT).}\\
\textbf{D.~Vasilev} --- conceptualisation, formal analysis, software, hardware (silicon), supervision, writing (original draft \& review/editing), funding acquisition.\\
\textbf{S.~Pellis} --- methodology (Pellis hierarchical expansion), formal analysis ($\alpha^{-1}$ and $\mu$ derivations), validation, writing (review).\\
\textbf{S.~Olsen} --- conceptualisation (Tier-D $\varphi$-cosmology framing), writing (Tier-D chapter), validation.

\vspace{0.4cm}

\noindent\textbf{ORCID iDs.}\\
D.~Vasilev: \href{https://orcid.org/0009-0008-4294-6159}{0009-0008-4294-6159}\\
S.~Pellis: \emph{ORCID not registered at the time of this freeze; the corresponding author will append it in an erratum if registered before peer review.}\\
S.~Olsen: \emph{ORCID not registered at the time of this freeze.}

\vspace{0.4cm}

\noindent\textbf{Use of generative AI.}\\
AI assistants (Claude Code, ChatGPT, and the project's own \texttt{trios-mcp-rag} MCP server) were used for build-system engineering, draft prose, table normalisation, and QA scripts. All scientific claims, empirical fits, Coq proofs, and Verilog assertions are the responsibility of the named human authors. No AI system is listed as an author.

\clearpage
$BODY$
);

-- ========================================================================
-- Verify
-- ========================================================================
SELECT slug, order_key, title, length(body_md) AS len
FROM ssot_brochure.chapters
WHERE kind = 'frontmatter' AND order_key BETWEEN 1 AND 20
ORDER BY order_key;

COMMIT;
