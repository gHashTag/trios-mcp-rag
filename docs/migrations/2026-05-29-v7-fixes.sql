-- GOLDEN CHAIN v7 SSOT migrations
-- Target: ssot_brochure.chapters
-- Backup: /tmp/pgbackup/all_chapters_pre_v7_20260529T121401Z.tsv (581 KB, 68 rows)
-- Author: agent / docs/agent-wake-up
-- Date: 2026-05-29
--
-- A5: DOI normalize — strip trailing punctuation [.,;)] from bare DOI numbers
--     (but NOT from DOIs inside markdown links [text](url) — those are fine)
-- A6: Bib unification — convert bare " 2509.22445 " → " arXiv:2509.22445 "
--     for tokens that look like arXiv IDs (NNNN.NNNNN) NOT already prefixed
-- A16: Tier D → Tier-D (when followed by space and not at sentence start)
--
-- Run inside a transaction, audit row counts, then COMMIT or ROLLBACK.

BEGIN;

-- A5: strip trailing ')' from bare DOI references not inside markdown link
-- These appear as "10.5281/zenodo.19227877)" not as "](https://...)"
-- We target the specific patterns observed in the audit.
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(
  body_md,
  '(\m10\.[0-9]{4,5}/[A-Za-z0-9._/-]+?)\.($|\s|[)\],;:])',
  '\1\2',
  'g'
);

UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(
  body_md,
  '(\m10\.[0-9]{4,5}/[A-Za-z0-9._/-]+?)\)(?!\()',
  '\1)',
  'g'
)
WHERE FALSE;  -- no-op placeholder; existing closing parens are usually legit markdown

-- A6: prefix bare arXiv IDs with "arXiv:" when they appear as
-- "arXiv 2509.22445" or stand-alone "2509.22445" inside a references block.
-- Conservative: only rewrite when "arXiv " (with space, no colon) is followed by a digit.
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(
  body_md,
  '\marXiv ([0-9]{4}\.[0-9]{4,6})\M',
  'arXiv:\1',
  'g'
);

-- A16: Tier D → Tier-D (only when followed by space + lowercase or "—" range)
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(
  body_md,
  '\mTier D(\s+[a-z—–-])',
  'Tier-D\1',
  'g'
);

-- Tier D at line start, end, or before period
UPDATE ssot_brochure.chapters
SET body_md = regexp_replace(
  body_md,
  '\mTier D([\.,;:!?\s\)])',
  'Tier-D\1',
  'g'
);

-- Audit: print row counts and a sample
SELECT 'A5_DOI_with_trailing_dot_remaining' AS check,
       count(*) AS rows
FROM ssot_brochure.chapters
WHERE body_md ~ '\m10\.[0-9]{4,5}/[A-Za-z0-9._/-]+?\.\s';

SELECT 'A6_bare_arXiv_remaining' AS check,
       count(*) AS rows
FROM ssot_brochure.chapters
WHERE body_md ~ '\marXiv [0-9]{4}\.';

SELECT 'A16_Tier_D_remaining' AS check,
       count(*) AS rows
FROM ssot_brochure.chapters
WHERE body_md ~ '\mTier D\M';

-- COMMIT;  -- uncommented after dry-run review
