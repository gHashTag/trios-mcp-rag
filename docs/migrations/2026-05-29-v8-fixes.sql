-- v8 migrations applied 2026-05-29 against ssot_brochure.chapters
-- (idempotent re-application is safe; each regex is targeted)

BEGIN;

-- B4: 10-N scientific notation → 10⁻N (Unicode superscript-minus)
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'([\\(≤≥<>×≲≳≅≈=±~]\\s*[0-9]*\\.?[0-9]*\\s*)10-([0-9]+)',
  E'\\110\u207B\\2', 'g');

-- B2: ASCII greek-name + digit → Unicode greek + digit (digit promoted later)
-- (Applied per-letter; see runbook.) Example:
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\malpha([0-9])\\M', E'\u03B1\\1', 'g');
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\mpi([0-9])\\M',    E'\u03C0\\1','g');
-- ...etc for beta, gamma, delta, epsilon, zeta, eta, theta, iota, kappa, lambda,
-- mu, nu, xi, rho, sigma, tau, upsilon, phi, chi, psi, omega.

-- Digit promotion: digit after Unicode greek or super-minus → Unicode super/sub digit
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'([\u03B1-\u03C9])0', E'\\1\u2080','g');
-- (1..9 follow with U+2081..U+2089)
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\u207B0', E'\u207B\u2070','g');
-- (1..9 follow with U+00B9, U+00B2, U+00B3, U+2074..U+2079)

-- B3: strip orphan figure-ref prefix
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'Figure \\(fig-[a-zA-Z0-9-]+\\)\\.\\s*', '', 'g');

-- B6: ell0..ell3 → ℓ₀..ℓ₃
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\mell0\\M', E'\u2113\u2080','g');
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\mell1\\M', E'\u2113\u2081','g');
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\mell2\\M', E'\u2113\u2082','g');
UPDATE ssot_brochure.chapters SET body_md = regexp_replace(body_md, E'\\mell3\\M', E'\u2113\u2083','g');

-- B7: strip leading "NN. " in ## headings
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'(?n)^(## )[0-9]+\\.([0-9]+)?\\.?\\s+', E'\\1', 'g');

-- B9/B10: london-handout typographic fixes
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(replace(body_md, '2026-05-19', '2026-05-29'),
  E'\\mExpansion3\\M', 'Expansion 3', 'g')
WHERE slug = 'london-handout';

-- B12: TBD codespan → \tbd{} badge
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'`TBD`', E'`\\\\tbd{real measurement pending}`', 'g')
WHERE slug = 'fm-13-depin-positioning';

-- B13: orphan [@cite] keys → plain "(refs. ...)" text
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'\\[@([a-zA-Z0-9_]+(?:;\\s*@[a-zA-Z0-9_]+)*)\\]', E'(refs. \\1)', 'g');

-- B17: strip body line that duplicates H1 (e.g. "8. Representative Empirical Results"
-- after "# P1 §8. Representative Empirical Results")
WITH parsed AS (
  SELECT slug,
         (regexp_matches(body_md, E'^# .*?§([0-9]+)\\. ([^\n]+)$', 'n'))[1] AS sec_num,
         (regexp_matches(body_md, E'^# .*?§([0-9]+)\\. ([^\n]+)$', 'n'))[2] AS sec_title
  FROM ssot_brochure.chapters)
UPDATE ssot_brochure.chapters c
SET body_md = regexp_replace(c.body_md,
  E'(?n)^' || p.sec_num || E'\\. ' ||
    regexp_replace(p.sec_title, '([\\.\\(\\)\\[\\]\\?\\*\\+\\\\])', E'\\\\\\1', 'g') || E'$',
  '', 'g')
FROM parsed p
WHERE c.slug = p.slug AND p.sec_num IS NOT NULL AND p.sec_title IS NOT NULL;

-- B1: claim-status badge inserts (6 body chapters)
-- (See runbook for the full inserts per slug.)

COMMIT;
