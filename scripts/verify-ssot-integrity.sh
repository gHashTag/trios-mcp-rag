#!/usr/bin/env bash
# verify-ssot-integrity.sh — comprehensive SSOT data-integrity audit
#
# Runs the 9-invariant audit suite developed across waves 28-35 of the
# GOLDEN CHAIN brochure project. Reports PASS/FAIL per invariant.
#
# Usage:
#   source .env   # provides DATABASE_URL
#   scripts/verify-ssot-integrity.sh
#
# Exit codes:
#   0 — all invariants pass
#   N — number of failed invariants
#   99 — environment misconfigured: no DSN OR schema-subset mode
#        (Path B / local TSV mirror without provenance columns)
#
# Skills bundled (wave-by-wave provenance):
#   wave 30 — chapters.sha256 = digest(body_md)
#   wave 31 — chapters.word_count = array_length(split_to_array(body_md, '\s+'))
#   wave 31 — chapters.illustration_url FK → assets.name
#   wave 32 — assets.byte_size = octet_length(bytes)
#   wave 32 — assets.sha256 = digest(bytes)
#   wave 32 — assets.chapter_slug FK → chapters.slug (where non-NULL)
#   wave 32 — chapters.format = 'markdown'
#   wave 33 — chapters.updated_at trigger present
#   wave 35 — body_md cross-refs (fm-NN, p[1-3]-NN, appx-XX) resolve to slugs

set -u
DB="${DATABASE_URL:-${TRIOS_DATABASE_URL:-}}"
if [ -z "$DB" ]; then
  echo "ERROR: DATABASE_URL or TRIOS_DATABASE_URL must be set." >&2
  exit 99
fi

# Preflight: detect Path B (local schema-subset mirror). Rule 09's nine
# invariants reference provenance columns (sha256, word_count, byte_size,
# format, asset_sha, updated_at) that only exist on Railway. Running
# against a local Path B mirror produces six confusing
# `column "X" does not exist` errors; this preflight surfaces the cause
# clearly and exits with the same 99 code as a missing DSN.
HAS_SHA256=$(psql "$DB" -At -c "SELECT count(*) FROM information_schema.columns WHERE table_schema='ssot_brochure' AND table_name='chapters' AND column_name='sha256';" 2>/dev/null || echo "X")
if [ "$HAS_SHA256" != "1" ]; then
  echo "" >&2
  echo "ERROR: schema-subset mode detected (Path B — local mirror)." >&2
  echo "" >&2
  echo "  Rule 09 invariants reference provenance columns that only" >&2
  echo "  exist on Railway (sha256, word_count, byte_size, format," >&2
  echo "  asset_sha, updated_at). The local TSV mirror is a strict" >&2
  echo "  six-column subset — see docs/agents/agent-bootstrap.md" >&2
  echo "  §'Schema subset note (Path B)'." >&2
  echo "" >&2
  echo "  Re-run this script against Path A (Pipedream connector) or" >&2
  echo "  Path C (Railway DSN via .env). Path B is not supported." >&2
  echo "" >&2
  exit 99
fi

FAIL=0
pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; FAIL=$((FAIL+1)); }

echo "=== GOLDEN CHAIN SSOT integrity audit (9 invariants) ==="

# 1. chapters.sha256
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.chapters WHERE encode(digest(convert_to(body_md,'UTF8'),'sha256'),'hex') != sha256;")
[ "$N" = "0" ] && pass "chapters.sha256 matches body (W35)" || fail "chapters.sha256 drift: $N rows"

# 2. chapters.word_count
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.chapters WHERE word_count IS DISTINCT FROM array_length(regexp_split_to_array(body_md,'\\s+'),1);")
[ "$N" = "0" ] && pass "chapters.word_count matches body (W36)" || fail "chapters.word_count drift: $N rows"

# 3. chapters.illustration_url FK
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.chapters c WHERE c.illustration_url IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ssot_brochure.assets a WHERE a.name = c.illustration_url);")
[ "$N" = "0" ] && pass "chapters.illustration_url FK clean" || fail "chapters.illustration_url dangling: $N rows"

# 4. assets.byte_size
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.assets WHERE byte_size IS DISTINCT FROM octet_length(bytes);")
[ "$N" = "0" ] && pass "assets.byte_size matches bytes" || fail "assets.byte_size drift: $N rows"

# 5. assets.sha256
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.assets WHERE sha256 IS DISTINCT FROM encode(digest(bytes,'sha256'),'hex');")
[ "$N" = "0" ] && pass "assets.sha256 matches bytes" || fail "assets.sha256 drift: $N rows"

# 6. assets.chapter_slug FK
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.assets a WHERE a.chapter_slug IS NOT NULL AND NOT EXISTS (SELECT 1 FROM ssot_brochure.chapters c WHERE c.slug = a.chapter_slug);")
[ "$N" = "0" ] && pass "assets.chapter_slug FK clean" || fail "assets.chapter_slug dangling: $N rows"

# 7. chapters.format
N=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.chapters WHERE format IS DISTINCT FROM 'markdown';")
[ "$N" = "0" ] && pass "chapters.format = 'markdown' (87/87)" || fail "chapters.format unexpected: $N rows"

# 8. updated_at trigger present
N=$(psql "$DB" -At -c "SELECT count(*) FROM pg_trigger WHERE tgrelid = 'ssot_brochure.chapters'::regclass AND tgname = 'chapters_touch_updated_at';")
[ "$N" = "1" ] && pass "chapters_touch_updated_at trigger present (W38)" || fail "updated_at trigger missing"

# 9. cross-reference resolution
# Every short-form xref token in body_md (fm-NN / p[1-3]-NN / appx-XX) must
# resolve to ≥1 chapter slug. Catches future typos like {fm-99} or {appx-zz}.
# Distinct xrefs as of wave 35: fm-01, fm-02, fm-06, fm-08, fm-09, fm-10,
# fm-11, fm-13 (1 chapter each) + appx-dna- (5) + appx-hw- (8) = 10 tokens.
N=$(psql "$DB" -At -c "WITH xrefs AS (SELECT DISTINCT (regexp_matches(body_md, '(fm-[0-9]+|p[1-3]-[0-9]+|appx-[a-z0-9-]+)', 'g'))[1] AS xref FROM ssot_brochure.chapters) SELECT count(*) FROM xrefs x WHERE NOT EXISTS (SELECT 1 FROM ssot_brochure.chapters c WHERE c.slug LIKE x.xref || '%');")
[ "$N" = "0" ] && pass "cross-references in body_md resolve (W47)" || fail "$N unresolved xref token(s)"

echo ""
echo "=== Summary ==="
TOTAL_CH=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.chapters;")
TOTAL_A=$(psql "$DB" -At -c "SELECT count(*) FROM ssot_brochure.assets;")
echo "  chapters: $TOTAL_CH    assets: $TOTAL_A"

if [ $FAIL -eq 0 ]; then
  echo ""
  echo "✅ All 9 invariants PASS — SSOT integrity certified."
  exit 0
else
  echo ""
  echo "❌ $FAIL invariant(s) FAILED — see above."
  exit $FAIL
fi
