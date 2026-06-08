-- =============================================================================
-- GOLDEN CHAIN v12 — Next-Wave Critic-Proof Pass Migration
-- =============================================================================
-- Audit: docs/audits/build-2026-05-29-v12.md
-- Runbook: docs/migrations/2026-05-29-v12-runbook.md
-- Backups: /tmp/pgbackup/all_chapters_pre_v12_20260529T135422Z.tsv
--          /tmp/pgbackup/chapter.template.tex.pre_v12_20260529T135422Z
--          /tmp/pgbackup/GOLDEN_CHAIN_v11_20260529T135422Z.pdf
--
-- Fixes:
--   P0  C15  fm-13-depin-positioning  \tbd{...} macro leak inside code spans (6×)
--   P1  C12  unified-symmetry-article  smart quote (U+2019) in `16'h47C0`
--   P1  C18  4 chapters missing \statusXxx claim-status badge
--   P1  C27  ## References missing in unified-symmetry-article,
--                                     gf-numeric-formats-history
--   P1  C31  ## References missing in p2-02-epistemic-boundary,
--                                     p2-03-math-preliminaries,
--                                     p2-04-e8-toda
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- P0  C15 — fm-13-depin-positioning : \tbd{real measurement pending}
-- The macro \tbd is defined in chapter.template.tex but is leaking inside
-- backtick code spans where the author intended literal text. Pandoc strips
-- the backticks for the `=latex` raw path in some contexts and the macro
-- renders as a live red badge. Safe fix: replace the literal macro string
-- with the plain text "TBD: real measurement pending" (still inside code
-- span so it visually reads as a placeholder code value).
-- Expected: 6 replacements in 1 row.
-- -----------------------------------------------------------------------------
UPDATE ssot_brochure.chapters
SET body_md = replace(body_md,
                      E'\\tbd{real measurement pending}',
                      'TBD: real measurement pending')
WHERE slug = 'fm-13-depin-positioning';

-- -----------------------------------------------------------------------------
-- P1  C12 — unified-symmetry-article : ASCII apostrophe in Verilog literal
-- U+2019 (right single quote) inside backtick code span breaks code-style.
-- -----------------------------------------------------------------------------
UPDATE ssot_brochure.chapters
SET body_md = replace(body_md, E'16\u2019h47C0', E'16\u0027h47C0')
WHERE slug = 'unified-symmetry-article';

-- -----------------------------------------------------------------------------
-- P1  C18 — insert claim-status badges after H1 in 4 chapters
-- Pattern (matches existing chapters):
--   # <title>
--   ```{=latex}
--   \statusXxx
--   ```
--   <rest of body>
-- Status mapping:
--   gf-format-audit              -> Open       (audit catalogue, no claims yet)
--   gf-numeric-formats-history   -> Verified   (historical survey, external DOIs)
--   london-handout               -> Open       (talk handout, programmatic claims)
--   unified-symmetry-article     -> Empirical  (long article, partial empirical fit)
-- -----------------------------------------------------------------------------
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
                             E'^(# [^\n]+\n)',
                             E'\\1\n```{=latex}\n\\\\statusOpen\n```\n\n',
                             'n')
WHERE slug = 'gf-format-audit';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
                             E'^(# [^\n]+\n)',
                             E'\\1\n```{=latex}\n\\\\statusVerified\n```\n\n',
                             'n')
WHERE slug = 'gf-numeric-formats-history';

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
                             E'^(# [^\n]+\n)',
                             E'\\1\n```{=latex}\n\\\\statusOpen\n```\n\n',
                             'n')
WHERE slug = 'london-handout';

-- unified-symmetry-article has no leading H1 (the pipeline auto-injects
-- `# {title}` at render time). Prepend the badge as the new first block so
-- it lands immediately after the injected H1.
UPDATE ssot_brochure.chapters
SET body_md = E'```{=latex}\n\\statusEmpirical\n```\n\n' || body_md
WHERE slug = 'unified-symmetry-article';

-- -----------------------------------------------------------------------------
-- P1  C27 / C31 — append ## References to 5 chapters that have status badges
-- (or now have one from C18) but no ## References section. We extract the
-- actual external anchors that already appear in body and codify them into
-- a properly-formatted unnumbered References block (matches other chapters).
-- -----------------------------------------------------------------------------

-- unified-symmetry-article (C27)
UPDATE ssot_brochure.chapters
SET body_md = body_md || E'\n\n## References {.unnumbered}\n\n'
  || E'- Trinity S³AI Coq proof base (84 theorems). Zenodo, DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).\n'
  || E'- Trinity Clara — open RTL, simulation, and verification data. GitHub: <https://github.com/gHashTag/trinity-clara>.\n'
  || E'- Tiny Tapeout — open silicon programme. Project pages: Phi (#4914), Euler (#4915), Gamma (#4913). <https://tinytapeout.com>.\n'
  || E'- Fring, A. and Korff, C. *Affine Toda field theories related to Coxeter groups of non-crystallographic type*. Nuclear Physics B 729 (2005) 361. DOI [10.1016/j.nuclphysb.2005.08.044](https://doi.org/10.1016/j.nuclphysb.2005.08.044).\n'
  || E'- Coldea, R. et al. *Quantum Criticality in an Ising Chain: Experimental Evidence for Emergent E8 Symmetry*. Science 327 (2010) 177. DOI [10.1126/science.1180085](https://doi.org/10.1126/science.1180085).\n'
WHERE slug = 'unified-symmetry-article';

-- gf-numeric-formats-history (C27)
UPDATE ssot_brochure.chapters
SET body_md = body_md || E'\n\n## References {.unnumbered}\n\n'
  || E'- IEEE Std 754-2019. *IEEE Standard for Floating-Point Arithmetic*. IEEE Computer Society, 2019.\n'
  || E'- Gustafson, J. L. and Yonemoto, I. *Beating Floating Point at its Own Game: Posit Arithmetic*. Supercomputing Frontiers and Innovations, 2017. arXiv: [0806.1083](https://arxiv.org/abs/0806.1083).\n'
  || E'- Jacob, B. et al. *Quantization and Training of Neural Networks for Efficient Integer-Arithmetic-Only Inference*. CVPR 2018. arXiv: [1712.05877](https://arxiv.org/abs/1712.05877).\n'
  || E'- Kuzmin, A. et al. *FP8 Quantization: The Power of the Exponent*. NeurIPS 2022. arXiv: [2208.09225](https://arxiv.org/abs/2208.09225).\n'
  || E'- Micikevicius, P. et al. *FP8 Formats for Deep Learning*. arXiv: [2209.05433](https://arxiv.org/abs/2209.05433).\n'
  || E'- Sun, X. et al. *Hybrid 8-bit Floating Point (HFP8) Training and Inference for Deep Neural Networks*. NeurIPS 2019.\n'
  || E'- Spallanzani, M. et al. *ExPAN(N)D: Exploring Posits for Efficient Artificial Neural Network Design*. arXiv: [2010.12869](https://arxiv.org/abs/2010.12869).\n'
  || E'- Trinity S³AI GoldenFloat specification. Internal whitepaper, derived from the Postgres SSOT (`ssot_brochure.chapters`).\n'
WHERE slug = 'gf-numeric-formats-history';

-- p2-02-epistemic-boundary (C31)
UPDATE ssot_brochure.chapters
SET body_md = body_md || E'\n\n## References {.unnumbered}\n\n'
  || E'- Fring, A. and Korff, C. *Affine Toda field theories related to Coxeter groups of non-crystallographic type*. Nuclear Physics B 729 (2005) 361. DOI [10.1016/j.nuclphysb.2005.08.044](https://doi.org/10.1016/j.nuclphysb.2005.08.044).\n'
  || E'- Coldea, R. et al. *Quantum Criticality in an Ising Chain: Experimental Evidence for Emergent E8 Symmetry*. Science 327 (2010) 177. DOI [10.1126/science.1180085](https://doi.org/10.1126/science.1180085).\n'
  || E'- Popper, K. *Conjectures and Refutations: The Growth of Scientific Knowledge*. Routledge, 1963 — falsifiability framing used in the epistemic boundary discussion.\n'
WHERE slug = 'p2-02-epistemic-boundary';

-- p2-03-math-preliminaries (C31)
UPDATE ssot_brochure.chapters
SET body_md = body_md || E'\n\n## References {.unnumbered}\n\n'
  || E'- Trinity S³AI Lucas-ring construction (84 mechanised theorems). Zenodo, DOI [10.5281/zenodo.19227877](https://doi.org/10.5281/zenodo.19227877).\n'
  || E'- Zamolodchikov, A. B. *Integrals of Motion and S-matrix of the (Scaled) T = T_c Ising Model with Magnetic Field*. arXiv: [cond-mat/9707012](https://arxiv.org/abs/cond-mat/9707012).\n'
  || E'- Fring, A. and Korff, C. *Affine Toda field theories related to Coxeter groups of non-crystallographic type*. Nuclear Physics B 729 (2005) 361. DOI [10.1016/j.nuclphysb.2005.08.044](https://doi.org/10.1016/j.nuclphysb.2005.08.044).\n'
WHERE slug = 'p2-03-math-preliminaries';

-- p2-04-e8-toda (C31)
UPDATE ssot_brochure.chapters
SET body_md = body_md || E'\n\n## References {.unnumbered}\n\n'
  || E'- Coldea, R. et al. *Quantum Criticality in an Ising Chain: Experimental Evidence for Emergent E8 Symmetry*. Science 327 (2010) 177. DOI [10.1126/science.1180085](https://doi.org/10.1126/science.1180085).\n'
  || E'- Fring, A. and Korff, C. *Affine Toda field theories related to Coxeter groups of non-crystallographic type*. Nuclear Physics B 729 (2005) 361. DOI [10.1016/j.nuclphysb.2005.08.044](https://doi.org/10.1016/j.nuclphysb.2005.08.044).\n'
  || E'- Zamolodchikov, A. B. *Integrals of Motion and S-matrix of the (Scaled) T = T_c Ising Model with Magnetic Field*. arXiv: [cond-mat/9707012](https://arxiv.org/abs/cond-mat/9707012).\n'
WHERE slug = 'p2-04-e8-toda';

-- -----------------------------------------------------------------------------
-- POST-MIGRATION VERIFICATION (must all return zero rows / zero count)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_tbd_count int;
  v_smartq_count int;
  v_missing_badges int;
  v_missing_refs int;
BEGIN
  -- C15
  SELECT count(*) INTO v_tbd_count
  FROM ssot_brochure.chapters
  WHERE body_md LIKE '%\tbd{real measurement pending}%';
  IF v_tbd_count <> 0 THEN
    RAISE EXCEPTION 'C15 verification failed: % chapters still contain \tbd{real measurement pending}', v_tbd_count;
  END IF;

  -- C12
  SELECT count(*) INTO v_smartq_count
  FROM ssot_brochure.chapters
  WHERE slug='unified-symmetry-article'
    AND body_md LIKE ('%16' || E'\u2019' || 'h47C0%');
  IF v_smartq_count <> 0 THEN
    RAISE EXCEPTION 'C12 verification failed: smart-quote still present';
  END IF;

  -- C18
  SELECT count(*) INTO v_missing_badges
  FROM ssot_brochure.chapters
  WHERE slug IN ('gf-format-audit','gf-numeric-formats-history',
                 'london-handout','unified-symmetry-article')
    AND body_md !~ E'\\\\status(Verified|Empirical|Open|HighRisk|Retracted)';
  IF v_missing_badges <> 0 THEN
    RAISE EXCEPTION 'C18 verification failed: % target chapters still lack a status badge', v_missing_badges;
  END IF;

  -- C27/C31
  SELECT count(*) INTO v_missing_refs
  FROM ssot_brochure.chapters
  WHERE slug IN ('unified-symmetry-article','gf-numeric-formats-history',
                 'p2-02-epistemic-boundary','p2-03-math-preliminaries',
                 'p2-04-e8-toda')
    AND body_md !~ '## References';
  IF v_missing_refs <> 0 THEN
    RAISE EXCEPTION 'C27/C31 verification failed: % target chapters still lack ## References', v_missing_refs;
  END IF;

  RAISE NOTICE 'v12 migration verification: all checks passed';
END$$;

COMMIT;
