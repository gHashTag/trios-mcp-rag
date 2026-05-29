-- =====================================================================
-- GOLDEN CHAIN v10 — SSOT migration ledger
-- =====================================================================
-- Date (UTC):     2026-05-29
-- Predecessor:    e6f4531 (v9 next wave critic-proof pass)
-- Operator:       AI agent on explicit maintainer go-ahead
-- Rollback:       /tmp/pgbackup/all_chapters_pre_v10_20260529T131610Z.tsv
--                 (+ template.tex.pre_v10 + force-fullwidth-hero.lua.pre_v10)
-- Safety:         All migrations idempotent under literal-substring or
--                 regex match. Wrap in a single transaction for atomicity.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- V1 (P0) — Fix orphan $$ in p3-13-phd-integration (v9 regression)
--   Before: x = $\sum_{k=0}$$\infty$ ck φ-k     (broken: $$ between two $)
--   After:  $x = \sum_{k=0}^{\infty} c_k\,\varphi^{-k}$
-- ---------------------------------------------------------------------
UPDATE ssot_brochure.chapters
   SET body_md = replace(
        body_md,
        E'x = $\\sum_{k=0}$$\\infty$ ck φ-k',
        E'$x = \\sum_{k=0}^{\\infty} c_k\\,\\varphi^{-k}$'
   )
 WHERE slug = 'p3-13-phd-integration';

-- Verify: dollar-dollar pairs must now be even
SELECT 'V1' AS step,
       (length(body_md) - length(replace(body_md, '$$', '')))/2 AS dd_count
  FROM ssot_brochure.chapters WHERE slug = 'p3-13-phd-integration';

-- ---------------------------------------------------------------------
-- V2 (P0) — Insert High-risk badge + claim-status disclaimer before
--           the Binnig / Prigogine historical quotations in fm-07.
--           Rule 5 enforcement on the most hype-prone passage in the
--           corpus ("I shall certainly present you for the next Nobel
--           Prize in Physics" — Prigogine to El Naschie, 2000).
-- ---------------------------------------------------------------------
UPDATE ssot_brochure.chapters
   SET body_md = replace(
        body_md,
        E'### Endorsements\n\nIn his March 17, 2004 letter nominating Mohamed El Naschie for the King\nFaisal award, Nobel Laureate **Gerd Binnig** wrote:',
        E'### Endorsements\n\n```{=latex}\n\\statusHighRisk\n```\n\n> **Claim status — High-risk historical material.** The two letters\n> reproduced below are **personal correspondence** between Nobel\n> laureates and Mohamed El Naschie (1976–2004). They are reproduced\n> *verbatim* from the author''s archive as **biographical context** for\n> the Tier-D contribution. They are **not endorsements of the TRIOS /\n> Golden Chain framework**, they are **not peer-reviewed validations**,\n> and any reference to a *future* Nobel Prize is the opinion of the\n> letter author about El Naschie''s separate E-infinity programme, not\n> a claim about this compendium. The TRIOS / Golden Chain prize\n> framing remains: prizes are **long-term external-validation\n> standards**, never deliverables. See §4 (Claim Status) of the\n> README and `references/04-claim-status.md` for the operating rule.\n\nIn his March 17, 2004 letter nominating Mohamed El Naschie for the King\nFaisal award, Nobel Laureate **Gerd Binnig** wrote:'
   )
 WHERE slug = 'fm-07-olsen-tier-d';

SELECT 'V2' AS step,
       position('statusHighRisk' in body_md) > 0 AS badge_present,
       position('Claim status — High-risk historical' in body_md) > 0 AS disclaim_present
  FROM ssot_brochure.chapters WHERE slug = 'fm-07-olsen-tier-d';

-- ---------------------------------------------------------------------
-- V3 (P0) — Escape literal $ in london-handout budget line
--   Before: "Budget up to $2M over 24 months"  -- pandoc reads $2M as
--           opening inline-math, leading to odd-$ parse error downstream
--   After:  "Budget up to \$2M over 24 months"
-- ---------------------------------------------------------------------
UPDATE ssot_brochure.chapters
   SET body_md = replace(body_md, 'Budget up to $2M', 'Budget up to \$2M')
 WHERE slug = 'london-handout'
   AND body_md LIKE '%Budget up to $2M%';

SELECT 'V3' AS step,
       (length(replace(body_md, E'\\$', '')) - length(replace(replace(body_md, E'\\$', ''), '$', ''))) AS unescaped_dollars_should_be_even
  FROM ssot_brochure.chapters WHERE slug = 'london-handout';

-- ---------------------------------------------------------------------
-- V4 (P1) — Suppress References subsections from TOC by annotating
--           every "## References" line with {.unnumbered}, which makes
--           pandoc emit \section*{References} (unnumbered → not in TOC).
--   Before: TOC contained 14 lines "X.Y References ......... NNN"
--   After:  TOC contains 0 such lines.
-- ---------------------------------------------------------------------
UPDATE ssot_brochure.chapters
   SET body_md = regexp_replace(
        body_md,
        E'^## References$',
        '## References {.unnumbered}',
        'gn'   -- 'n' = newline-sensitive (Postgres flag for multiline ^$)
   );

SELECT 'V4' AS step,
       count(*) FILTER (WHERE body_md LIKE '%## References {.unnumbered}%') AS annotated_rows,
       count(*) FILTER (WHERE body_md ~ E'(?n)^## References$') AS still_plain_should_be_zero
  FROM ssot_brochure.chapters;

-- ---------------------------------------------------------------------
-- V5 / V6 (P1) — Typographic ASCII → smart Unicode in prose.
-- NOT a SQL migration. Implemented in src/pipeline.rs:
--   pandoc.arg("--from=markdown+smart");
-- Effect:
--   "X" → "X" (curly quotes)
--   '   → ’ (curly apostrophe)
--   --  → — (em-dash)
--   ... → … (ellipsis)
-- Pandoc smart extension is conservative inside code, math, and raw
-- blocks. Verified visually on Olsen quotations (pages 67–68).
-- ---------------------------------------------------------------------

COMMIT;
