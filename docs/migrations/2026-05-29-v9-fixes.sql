-- v9 SSOT migration ledger — 2026-05-29 next wave critic-proof pass
-- Schema: ssot_brochure.chapters
-- Backups: /tmp/pgbackup/all_chapters_pre_v9_20260529T125532Z.tsv
-- See: docs/audits/build-2026-05-29-v9.md, docs/migrations/2026-05-29-v9-runbook.md

-- =========================================================================
-- V1: Mojibake ∈fty / ∈t → $\infty$ / $\int$ (10 chapters)
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '∈fty', '$\infty$', 'g')
WHERE body_md ~ '∈fty';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '∈t( )', '$\int$\1', 'g')
WHERE body_md ~ '∈t ';

COMMIT;

-- =========================================================================
-- V2: ASCII math snippet wrap (greek-macro + single-letter math anchors)
-- =========================================================================
BEGIN;

-- Greek-name caret-star → inline math with greek TeX macros
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mmu\^\*', '$\mu^{*}$', 'g')
WHERE body_md ~ '\mmu\^\*';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mlambda\^\*', '$\lambda^{*}$', 'g')
WHERE body_md ~ '\mlambda\^\*';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mgi\^\*', '$g_i^{*}$', 'g')
WHERE body_md ~ '\mgi\^\*';

-- muT( → $\mu_T$(
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mmuT\(', '$\mu_T$(', 'g')
WHERE body_md ~ '\mmuT\(';

-- Single-letter math anchors (F, R, T, C, S, P, G, g, M) with ^* or ^+
-- Negative lookbehind on $ and \ to skip already-wrapped instances
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '(?<![$\\])([FRTCSPGgM])\^([*+])', '$\1^{\2}$', 'g')
WHERE body_md ~ '(?<![$\\])[FRTCSPGgM]\^[*+]';

COMMIT;

-- =========================================================================
-- V3: limsupL / liminfL fragmented → $\limsup_{L}$
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mlimsupL\M', '$\limsup_{L}$', 'g')
WHERE body_md ~ '\mlimsupL\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mliminfL\M', '$\liminf_{L}$', 'g')
WHERE body_md ~ '\mliminfL\M';

COMMIT;

-- =========================================================================
-- V9: sum/prod tokens → inline math
-- =========================================================================
BEGIN;

-- sumc=X → $\sum_{c=X}$
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumc(\s*=\s*[-0-9a-zA-Z])', '$\sum_{c\1}$', 'g')
WHERE body_md ~ '\msumc\s*=';
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumc\M', '$\sum_{c}$', 'g')
WHERE body_md ~ '\msumc\M';

-- sumk
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumk(\s*=\s*[-0-9a-zA-Z])', '$\sum_{k\1}$', 'g')
WHERE body_md ~ '\msumk\s*=';
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumk\M', '$\sum_{k}$', 'g')
WHERE body_md ~ '\msumk\M';

-- sumi, sumn, sumj
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumi(\s*=\s*[-0-9a-zA-Z])', '$\sum_{i\1}$', 'g')
WHERE body_md ~ '\msumi\s*=';
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumi\M', '$\sum_{i}$', 'g')
WHERE body_md ~ '\msumi\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumn(\s*=\s*[-0-9a-zA-Z])', '$\sum_{n\1}$', 'g')
WHERE body_md ~ '\msumn\s*=';
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumn\M', '$\sum_{n}$', 'g')
WHERE body_md ~ '\msumn\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\msumj\M', '$\sum_{j}$', 'g')
WHERE body_md ~ '\msumj\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mprodk\M', '$\prod_{k}$', 'g')
WHERE body_md ~ '\mprodk\M';

COMMIT;

-- =========================================================================
-- V4 + V10: lfloor / rfloor / lceil / rceil ASCII → Unicode
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\m(?<!\\)lfloor\M', '⌊', 'g')
WHERE body_md ~ '\m(?<!\\)lfloor\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\m(?<!\\)rfloor\M', '⌋', 'g')
WHERE body_md ~ '\m(?<!\\)rfloor\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\m(?<!\\)lceil\M', '⌈', 'g')
WHERE body_md ~ '\m(?<!\\)lceil\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\m(?<!\\)rceil\M', '⌉', 'g')
WHERE body_md ~ '\m(?<!\\)rceil\M';

-- V10: joined-token cleanup (lceillog2 etc.)
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, 'lceil(log)', '⌈\1', 'g')
WHERE body_md ~ 'lceillog';

COMMIT;

-- =========================================================================
-- V5: Raw phi^N → $\varphi^{N}$ (only outside TeX-escaped contexts)
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '(?<!\\)\mphi\^(-?[0-9]+)', '$\varphi^{\1}$', 'g')
WHERE body_md ~ '(?<!\\)\mphi\^-?[0-9]';

COMMIT;

-- =========================================================================
-- V6: Multi-digit greek subscript residuals
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mpsi17\M', 'ψ₁₇', 'g')
WHERE body_md ~ '\mpsi17\M';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\mtheta13\M', 'θ₁₃', 'g')
WHERE body_md ~ '\mtheta13\M';

COMMIT;

-- =========================================================================
-- V7: S3AI body leak (p3-13 only — fm-01g keeps codespan intentionally)
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, 'TRINITY S3AI', 'TRINITY S³AI')
WHERE slug = 'p3-13-phd-integration';

COMMIT;

-- =========================================================================
-- V8: Claim-status badge injection (31 new chapters)
-- =========================================================================
BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.inject_badge(p_slug TEXT, p_badge TEXT)
RETURNS VOID AS $func$
DECLARE
  cur TEXT;
  newbody TEXT;
BEGIN
  SELECT body_md INTO cur FROM ssot_brochure.chapters WHERE slug=p_slug;
  IF cur IS NULL THEN RETURN; END IF;
  IF cur ~ '\\status(Verified|Empirical|Open|HighRisk|Retracted)' THEN RETURN; END IF;
  newbody := regexp_replace(
    cur,
    E'^(# [^\\n]+\\n\\n)',
    E'\\1```{=latex}\n\\' || p_badge || E'\n```\n\n',
    'n'
  );
  IF newbody = cur THEN
    newbody := E'```{=latex}\n\\' || p_badge || E'\n```\n\n' || cur;
  END IF;
  UPDATE ssot_brochure.chapters SET body_md=newbody WHERE slug=p_slug;
END;
$func$ LANGUAGE plpgsql;

-- Verified (textbook material, no novel claim)
SELECT pg_temp.inject_badge('p1-02-background', 'statusVerified');
SELECT pg_temp.inject_badge('p2-02-epistemic-boundary', 'statusVerified');
SELECT pg_temp.inject_badge('p2-03-math-preliminaries', 'statusVerified');
SELECT pg_temp.inject_badge('p3-02-notation', 'statusVerified');
SELECT pg_temp.inject_badge('p2-04-e8-toda', 'statusVerified');

-- Empirical fit (data-driven results)
SELECT pg_temp.inject_badge('p1-05-null-models', 'statusEmpirical');
SELECT pg_temp.inject_badge('p1-06-multiple-testing', 'statusEmpirical');
SELECT pg_temp.inject_badge('p1-07-mdl-bayesian', 'statusEmpirical');
SELECT pg_temp.inject_badge('p3-07-mdl', 'statusEmpirical');

-- Open conjecture (proposed methods / programs / forward claims)
SELECT pg_temp.inject_badge('p1-01-introduction', 'statusOpen');
SELECT pg_temp.inject_badge('p1-03-symbolic-grammar', 'statusOpen');
SELECT pg_temp.inject_badge('p1-04-target-dataset', 'statusOpen');
SELECT pg_temp.inject_badge('p1-09-pellis-expansion', 'statusOpen');
SELECT pg_temp.inject_badge('p1-12-flos-aureus-link', 'statusOpen');
SELECT pg_temp.inject_badge('p2-01-motivation', 'statusOpen');
SELECT pg_temp.inject_badge('p2-05-symbolic-rg', 'statusOpen');
SELECT pg_temp.inject_badge('p2-06-phi-operator', 'statusOpen');
SELECT pg_temp.inject_badge('p2-07-dsi', 'statusOpen');
SELECT pg_temp.inject_badge('p2-08-a5-flavor', 'statusOpen');
SELECT pg_temp.inject_badge('p2-09-flos-aureus-link', 'statusOpen');
SELECT pg_temp.inject_badge('p2-12-roadmap', 'statusOpen');
SELECT pg_temp.inject_badge('p3-01-introduction', 'statusOpen');
SELECT pg_temp.inject_badge('p3-03-trinity-monomials', 'statusOpen');
SELECT pg_temp.inject_badge('p3-04-pellis-expansion', 'statusOpen');
SELECT pg_temp.inject_badge('p3-05-projection', 'statusOpen');
SELECT pg_temp.inject_badge('p3-06-koopman', 'statusOpen');
SELECT pg_temp.inject_badge('p3-09-computational', 'statusOpen');
SELECT pg_temp.inject_badge('p3-12-conclusion', 'statusOpen');
SELECT pg_temp.inject_badge('p3-13-phd-integration', 'statusOpen');

-- High-risk (limitations + reviewer risk chapters)
SELECT pg_temp.inject_badge('p1-11-reviewer-risk', 'statusHighRisk');
SELECT pg_temp.inject_badge('p1-13-limitations', 'statusHighRisk');
SELECT pg_temp.inject_badge('p2-10-work-packages', 'statusHighRisk');
SELECT pg_temp.inject_badge('p2-11-limitations', 'statusHighRisk');
SELECT pg_temp.inject_badge('p3-11-limitations', 'statusHighRisk');

COMMIT;

-- =========================================================================
-- Cross-cutting: \(...\) → $...$ form (pandoc default markdown compat)
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, '\\\(([^)]*?)\\\)', '$\1$', 'g')
WHERE body_md ~ '\\\(';

COMMIT;

-- =========================================================================
-- Cross-cutting: 8-space dedent for theorem blocks (verbatim leak)
-- =========================================================================
BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'        Theorem 4.4 (Exponential', E'  Theorem 4.4 (Exponential')
WHERE slug='p3-04-pellis-expansion';
UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'        Proof. Follows from Proposition 4.2', E'  Proof. Follows from Proposition 4.2')
WHERE slug='p3-04-pellis-expansion';
UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'        φ-(D+1)) at each step', E'  φ-(D+1)) at each step')
WHERE slug='p3-04-pellis-expansion';

UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'        and $\\mu_T$', E'  and $\\mu_T$')
WHERE slug='p3-05-projection';
UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'        numerator in the defining ratio', E'  numerator in the defining ratio')
WHERE slug='p3-05-projection';

COMMIT;
