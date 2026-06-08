-- GOLDEN CHAIN v11 — next wave critic-proof pass migrations
-- Date: 2026-05-29 (UTC)
-- Author: agent (autonomous run)
-- Pre-state: HEAD 04921bf (v10), 69 chapters, 14 order_key collision groups,
--   16 phantom \chapter{} commands in main.tex (85 actual vs 69 SSOT rows).
-- Backups: /tmp/pgbackup/all_chapters_pre_v11_20260529T133416Z.tsv (69 rows)
-- Rollback: \COPY ssot_brochure.chapters FROM '<backup>.tsv' ... after TRUNCATE.

BEGIN;

-- ============================================================
-- B10 P0 — order_key collision resolution
-- ----------------------------------------------------------
-- Compound deterministic renumber: kind_rank * 1000 + sequential*10.
-- Within each kind block, preserve current (order_key ASC, slug ASC) order.
-- Step size 10 leaves room for future insertions.
-- ============================================================

WITH ranked AS (
  SELECT slug,
    CASE kind
      WHEN 'frontmatter' THEN 0
      WHEN 'paper1' THEN 1
      WHEN 'paper2' THEN 2
      WHEN 'paper3' THEN 3
      WHEN 'audit' THEN 4
      WHEN 'unified' THEN 5
      WHEN 'cover' THEN 6
      WHEN 'outreach' THEN 7
      WHEN 'handout' THEN 8
      ELSE 9
    END * 1000 + ROW_NUMBER() OVER (
      PARTITION BY kind ORDER BY order_key ASC, slug ASC
    ) * 10 AS new_order_key
  FROM ssot_brochure.chapters
)
UPDATE ssot_brochure.chapters c
SET order_key = r.new_order_key
FROM ranked r
WHERE c.slug = r.slug;

-- Verify: no duplicates
SELECT 'B10 verify: dup count', COUNT(*)
FROM (
  SELECT order_key FROM ssot_brochure.chapters GROUP BY order_key HAVING COUNT(*) > 1
) d;

-- ============================================================
-- B16 P0 — demote body-level H1 to H2 (avoids phantom \chapter)
-- ----------------------------------------------------------
-- For chapters with multiple `# ` headings, the FIRST H1 is the title;
-- all subsequent body `# ` lines (appendices etc.) become \chapter in
-- LaTeX which pollutes the TOC and breaks chapter count.
-- Strategy: replace any `\n# ` (i.e., # at line start after first occurrence)
-- with `\n## `. Postgres regex flag 'gn' (global, newline-sensitive).
-- ============================================================

-- p1-14-conclusion: 1 title + 4 body H1s → demote body H1s
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'\n# (P1 Appendix [A-Z])', E'\n## \\1', 'gn')
WHERE slug = 'p1-14-conclusion';

-- p3-13-phd-integration: 1 title + 5 body H1s
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'\n# (P3 Appendix [A-Z])', E'\n## \\1', 'gn')
WHERE slug = 'p3-13-phd-integration';

-- london-handout: 1 title + 7 body H1s (Appendix F.x)
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'\n# (Appendix F[\\.\\d]*)', E'\n## \\1', 'gn')
WHERE slug = 'london-handout';

-- unified-symmetry-article: NO leading H1, all 12 H1s are body sections.
-- B15+B16 combined: prepend article title as # H1, demote all existing # → ##.
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md, E'^# ', E'## ', 'gn')
WHERE slug = 'unified-symmetry-article';

-- Now unified-symmetry-article has no H1; pipeline's render_markdown will
-- inject `# {title}` (line 278) — that's the desired path. Verify after.

-- ============================================================
-- B15 P0 — chapters with no leading H1 → relying on pipeline injection
-- ----------------------------------------------------------
-- authority-outreach-templates and cover-letter-symmetry start with **bold**
-- text. Pipeline's render_markdown line 278 emits `# {title}` for those.
-- No SSOT change needed; they're already handled by pipeline.
-- (Verified by reading src/pipeline.rs lines 263-280.)
-- ============================================================

-- ============================================================
-- B11 P1 — title vs body first-H1 drift alignment
-- ----------------------------------------------------------
-- SSOT `title` is canonical (used in TOC, \chaptermark, \addcontentsline).
-- Align body's first H1 to match `title` exactly.
-- ============================================================

-- fm-01-cover: H1 is shorter, expand to full title
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# [^\\n]+',
  E'# GOLDEN CHAIN — Armoured Provenance Layer for DePIN (A Three-Strand Compendium on φ-Structured Physical Constants)',
  'n')
WHERE slug = 'fm-01-cover';

-- fm-02-attribution: align H1 to full title
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# [^\\n]+',
  E'# Attribution & Provenance — Triple-Author Manifest (Vasilev · Pellis · Olsen)',
  'n')
WHERE slug = 'fm-02-attribution';

-- fm-04-alpha-reconciliation: align H1
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# [^\\n]+',
  E'# α⁻¹ Reconciliation Table — CODATA, Pellis Golden-Angle, Pellis Archimedes',
  'n')
WHERE slug = 'fm-04-alpha-reconciliation';

-- fm-07-olsen-tier-d: ":" vs " — " — align to title's em-dash
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# Olsen Tier-D: ',
  E'# Olsen Tier-D — ',
  'n')
WHERE slug = 'fm-07-olsen-tier-d';

-- fm-08-methodology-rigor: H1 is longer than title — keep title canonical,
-- truncate H1 to match SSOT title.
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# Methodology and Scientific Rigor — Pre-Registered Protocol for GOLDEN CHAIN',
  E'# Methodology and Scientific Rigor — Pre-Registered Protocol',
  'n')
WHERE slug = 'fm-08-methodology-rigor';

-- fm-12-constants-table: align H1
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# [^\\n]+',
  E'# Consolidated Constants Catalog — Vasilev Trinity vs. Pellis (200+ formulas)',
  'n')
WHERE slug = 'fm-12-constants-table';

-- gf-format-audit: reorder phrasing, align to SSOT title
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# Trinity GoldenFloat Family — Unified Specification Audit',
  E'# GF Format Audit — Trinity GoldenFloat Family Unified Specification',
  'n')
WHERE slug = 'gf-format-audit';

-- london-handout: H1 is brand header, replace with SSOT title.
-- (Already demoted body H1s above; the first remaining # line is the original
-- "Trinity S³AI / GOLDEN CHAIN" header.)
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(body_md,
  E'^# Trinity S³AI / GOLDEN CHAIN',
  E'# London Handout — Trinity S³AI Side Session',
  'n')
WHERE slug = 'london-handout';

-- ============================================================
-- Final verification
-- ============================================================
SELECT 'final: total chapters', COUNT(*) FROM ssot_brochure.chapters;

SELECT 'B10 final: dup count', COUNT(*)
FROM (
  SELECT order_key FROM ssot_brochure.chapters GROUP BY order_key HAVING COUNT(*) > 1
) d;

SELECT 'B16 final: chapters with >1 body H1' AS check_name, COUNT(*) AS n
FROM ssot_brochure.chapters
WHERE (LENGTH(body_md) - LENGTH(REPLACE(body_md, E'\n# ', ''))) / 3 > 0;

SELECT 'B11 final: title vs first-H1 mismatches' AS check_name, COUNT(*) AS n
FROM (
  SELECT slug, title, SUBSTRING(body_md FROM E'^# ([^\n]+)') AS h1
  FROM ssot_brochure.chapters
) sub
WHERE h1 IS NOT NULL
  AND REGEXP_REPLACE(h1, '\s*\{[^}]*\}\s*$', '') != title;

COMMIT;
