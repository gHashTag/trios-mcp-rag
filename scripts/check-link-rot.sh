#!/usr/bin/env bash
#
# check-link-rot.sh — executable enforcement of rule 10's
# "Link-rot pre-flight" subsection
# (docs/agent-rules/10-next-wave-workflow.md).
#
# Three sub-checks (each is a v17 forensic audit finding):
#
#   1. Every docs/audits/build-*-vNN.md is referenced from at least
#      one entry point: README.md, CLAUDE.md, AGENTS.md, or
#      docs/agents/agent-bootstrap.md. v16 orphaned its own audit
#      doc because no entry point linked to it; v17 added an executable
#      gate so the same failure mode cannot reach `main`.
#
#   2. Every local .md → .md link in tracked files resolves on disk.
#      Catches the v15-class regression where README pointed at
#      missing sister-repo docs.
#
#   3. docs/agents/agent-bootstrap.md "Latest audit" pointer points
#      at the highest-numbered build-*-vNN.md on disk. Catches the
#      v12→v16 pointer-pin failure mode v17 P0.2 fixed.
#
# Exit codes:
#   0  clean
#   1  some local .md link is broken (sub-check 2)
#   2  some audit doc is orphaned (sub-check 1)
#   3  Latest-audit pointer is stale (sub-check 3)
#
# Inputs: none. Always run from the repo root.
# Outputs: human-readable diagnostics to stdout; errors to stderr.

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

rc=0
ENTRY_POINTS=(README.md CLAUDE.md AGENTS.md docs/agents/agent-bootstrap.md)

# ----- Sub-check 1: audit-doc orphan scan (recent 5 audits only) -----
# Rationale: pre-v13 audits are intentionally archived and not linked
# from entry points; new orphans appear only when a fresh audit doc is
# created without being linked (v16's failure mode). Scoping to the
# top-5 most-recent audits by version number catches the regression
# without flagging the deep historical record. Adjust ORPHAN_WINDOW if
# the policy changes.
ORPHAN_WINDOW=5
echo "[1/3] audit-doc orphan scan (last $ORPHAN_WINDOW)"
orphan_count=0
recent_audits=$(ls docs/audits/build-2026-05-29-v[0-9]*.md 2>/dev/null \
  | sed -E 's#.*-v([0-9]+)\.md$#\1\t&#' \
  | sort -n \
  | tail -"$ORPHAN_WINDOW" \
  | cut -f2)
for audit in $recent_audits; do
  [ -f "$audit" ] || continue
  base=$(basename "$audit")
  if ! grep -Fql "$base" "${ENTRY_POINTS[@]}" 2>/dev/null; then
    echo "  ORPHAN: $audit (no entry point references it)" >&2
    orphan_count=$((orphan_count + 1))
  fi
done
if [ "$orphan_count" -gt 0 ]; then
  echo "  → $orphan_count orphaned audit doc(s) in last $ORPHAN_WINDOW" >&2
  rc=2
else
  echo "  OK (no orphans in last $ORPHAN_WINDOW)"
fi

# ----- Sub-check 2: local .md link resolution -----
echo "[2/3] local .md link resolution"
broken=$(python3 - <<'PY'
import os, re, sys
# Skip generic placeholder targets that appear in documentation examples
# (e.g. "](path.md)", "](file.md)", "](some.md)"). Real links always
# contain at least one '/' or a dated/numbered prefix.
PLACEHOLDERS = {'path.md', 'file.md', 'some.md', 'foo.md', 'bar.md',
                'example.md', 'NN-something.md'}
broken=[]
for dirpath, dirs, files in os.walk('.'):
    if '/.git' in dirpath: continue
    if '/generated' in dirpath: continue
    if '/target' in dirpath: continue
    if dirpath.startswith('./skills'): continue  # skills mirror checked separately
    for f in files:
        if not f.endswith('.md'): continue
        p=os.path.join(dirpath,f)
        try:
            with open(p) as fh: txt=fh.read()
        except: continue
        # Strip fenced code blocks so example code inside ``` ... ``` is not
        # treated as a real link.
        txt = re.sub(r'```.*?```', '', txt, flags=re.S)
        for m in re.finditer(r'\]\(([^)#\s]+\.md)(?:#[^)]*)?\)', txt):
            target=m.group(1)
            if target.startswith('http'): continue
            if target in PLACEHOLDERS: continue
            full=os.path.normpath(os.path.join(os.path.dirname(p), target))
            if not os.path.exists(full):
                broken.append(f"{p}: {target} not found at {full}")
for b in broken: print(b)
sys.exit(0)
PY
)
if [ -n "$broken" ]; then
  echo "$broken" >&2
  bcount=$(printf '%s\n' "$broken" | wc -l)
  echo "  → $bcount broken link(s)" >&2
  [ "$rc" -eq 0 ] && rc=1
else
  echo "  OK (no broken local .md links)"
fi

# ----- Sub-check 3: Latest-audit pointer freshness -----
echo "[3/3] Latest-audit pointer freshness"
latest_on_disk=$(ls docs/audits/build-2026-05-29-v[0-9]*.md 2>/dev/null \
  | sed -E 's#.*-v([0-9]+)\.md$#\1#' \
  | sort -n \
  | tail -1)
bootstrap=docs/agents/agent-bootstrap.md
if [ -f "$bootstrap" ] && [ -n "$latest_on_disk" ]; then
  # Match specifically the "Latest audit:" line to avoid picking up the
  # "previous: v16, v15, ..." chain that follows it.
  pointer_v=$(grep -E '^- Latest audit:' "$bootstrap" \
    | grep -oE 'build-2026-05-29-v[0-9]+\.md' \
    | head -1 \
    | sed -E 's#.*-v([0-9]+)\.md$#\1#')
  if [ "$pointer_v" = "$latest_on_disk" ]; then
    echo "  OK (Latest audit pointer = v$pointer_v = highest on disk)"
  else
    echo "  STALE: agent-bootstrap.md Latest audit pointer = v$pointer_v but highest on disk = v$latest_on_disk" >&2
    [ "$rc" -eq 0 ] && rc=3
  fi
else
  echo "  SKIP (missing bootstrap or no audits on disk)"
fi

echo "---"
case "$rc" in
  0) echo "check-link-rot: CLEAN" ;;
  1) echo "check-link-rot: BROKEN LINKS (rc=1)" >&2 ;;
  2) echo "check-link-rot: ORPHANED AUDIT(S) (rc=2)" >&2 ;;
  3) echo "check-link-rot: STALE POINTER (rc=3)" >&2 ;;
esac
exit "$rc"
