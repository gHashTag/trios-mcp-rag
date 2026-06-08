-- ======================================================================
-- Migration: 2026-06-08-multi-doc
-- Repo: gHashTag/trios-mcp-rag
-- Branch: feat/multi-doc-ssot
-- Purpose: ONE SSOT for ALL papers. Add `doc` column to chapters so
--          GOLDEN CHAIN compendium and paper3-methodology coexist
--          in the same table, queried via the same MCP build_pdf tool.
-- ======================================================================
-- HARD RULES (carry from agent-rules/03-safety-railway-postgres.md):
--   1) Run backup_ssot(confirm=true) BEFORE applying this migration.
--   2) Apply inside a single transaction; rollback on any failure.
--   3) Existing 69 rows MUST keep doc='golden-chain-compendium' default
--      so build_pdf() with no doc filter behaves identically to today.
--   4) No data loss: column is added with NOT NULL DEFAULT, then existing
--      rows are tagged, then default is dropped (so future inserts MUST
--      specify doc explicitly).
-- ======================================================================

BEGIN;

-- 1. Snapshot count before
SELECT 'rows_before' AS step, COUNT(*) AS n FROM ssot_brochure.chapters;

-- 2. Add doc column (NOT NULL with default so existing rows get tagged)
ALTER TABLE ssot_brochure.chapters
  ADD COLUMN IF NOT EXISTS doc TEXT NOT NULL
    DEFAULT 'golden-chain-compendium';

-- 3. Verify all existing rows tagged
SELECT 'rows_tagged_compendium' AS step, COUNT(*) AS n
  FROM ssot_brochure.chapters
  WHERE doc = 'golden-chain-compendium';

-- 4. Drop default so future inserts MUST specify doc explicitly
ALTER TABLE ssot_brochure.chapters
  ALTER COLUMN doc DROP DEFAULT;

-- 5. Composite index for fast per-doc ordered fetch
CREATE INDEX IF NOT EXISTS ix_chapters_doc_order
  ON ssot_brochure.chapters (doc, order_key);

-- 6. Documenting the columns (psql \d+ shows COMMENTs)
COMMENT ON COLUMN ssot_brochure.chapters.doc IS
  'Document slug grouping chapters into a single PDF artefact. '
  'Canonical values: golden-chain-compendium (69 rows, v12 baseline), '
  'paper3-methodology (84-format catalog paper, 9 sections, arXiv #3).';

-- 7. Snapshot after
SELECT 'rows_after' AS step, COUNT(*) AS n FROM ssot_brochure.chapters;
SELECT 'distinct_docs' AS step, doc, COUNT(*) AS n
  FROM ssot_brochure.chapters
  GROUP BY doc
  ORDER BY doc;

COMMIT;

-- ======================================================================
-- Rollback (run ONLY if migration failed mid-transaction and was
-- partially committed against the safety rules above):
--
--   BEGIN;
--   DROP INDEX IF EXISTS ix_chapters_doc_order;
--   ALTER TABLE ssot_brochure.chapters DROP COLUMN IF EXISTS doc;
--   COMMIT;
-- ======================================================================
