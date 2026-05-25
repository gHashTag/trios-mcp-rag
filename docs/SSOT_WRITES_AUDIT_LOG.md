# SSOT Writes — Audit Log

> Per [`docs/agent-rules/03-safety-railway-postgres.md`](agent-rules/03-safety-railway-postgres.md):
> every write to `ssot_brochure.*` must be backed up, dry-run-reviewed,
> confirmed in-session, and logged with a rollback plan.
> This file is the running log for the GOLDEN CHAIN brochure v11.

## Session: 2026-05-25 (DePIN positioning + Olsen narrative)

Schema: `ssot_brochure`
Database: Railway Postgres (via `DATABASE_URL`, env-only).
Confirmation: each write authorised by the maintainer in-session.

### Snapshots (rollback targets, do not drop)

| Snapshot table | When | Captures |
|---|---|---|
| `ssot_brochure.chapters_backup_20260525_depin` | before W1 | full table, 80 rows |
| `ssot_brochure._fm13_14_before_urls` | before W3 | fm-13 + fm-14 rows |
| `ssot_brochure.fm07_before_olsen_append` | before W4 | fm-07 row |
| `ssot_brochure._fm01_before_rename` | before W5 | fm-01 row |

### W1 — INSERT `fm-13-depin-positioning`

- **Why:** position TRIOS Three Crowns as armoured-provenance layer for
  DePIN (not a high-throughput inference accelerator), with verified
  citations to IoTeX W3bstream, peaq verify tiers, RFC 9334 RATS, NIST
  Ascon, OpenTitan.
- **What:**
  ```sql
  INSERT INTO ssot_brochure.chapters
    (slug, kind, order_key, title, body_md, illustration_url, word_count, sha256, format)
  VALUES (
    'fm-13-depin-positioning', 'frontmatter', 65,
    'Armoured Provenance Layer for DePIN — Three Crowns as a Trust Co-Processor',
    <body from /tmp/fm13_body.md, base64-encoded>,
    NULL, <computed>, <sha256 hex>, 'markdown'
  );
  ```
- **Verify:** `slug='fm-13-...', body_len=5984, word_count=841, sha256=e85abf8ba084…`
- **Rollback:** `DELETE FROM ssot_brochure.chapters WHERE slug='fm-13-depin-positioning';`

### W2 — INSERT `fm-14-competitive-landscape`

- **Why:** map the 7 competitor layers (DePIN verification protocols,
  machine-economy L1, domain-specific DePIN proofs, oracle layer,
  TEE-as-a-service, secure elements, confidential compute) and locate
  TRIOS in the gap between secure element and TEE.
- **Verify:** `slug='fm-14-...', body_len=9168, word_count=1234, sha256=2f7467e92ad6…`
- **Rollback:** `DELETE FROM ssot_brochure.chapters WHERE slug='fm-14-competitive-landscape';`

### W3 — UPDATE `fm-13` + `fm-14` — wrap bare URLs in `<https://...>`

- **Why:** pandoc was emitting backticked / plain URLs as `\texttt{}` /
  plain text → no breakability → references list overflowed the right
  margin. Wrapping in angle brackets makes pandoc emit `\url{}` which
  `xurl` can break.
- **What:** `regexp_replace` over `body_md` for each row.
- **Verify:** `fm-13` body 5924B → 5984B (+60B); `fm-14` 9072B → 9168B (+96B).
- **Rollback:** `UPDATE ssot_brochure.chapters c SET body_md=b.body_md, sha256=b.sha256 FROM ssot_brochure._fm13_14_before_urls b WHERE c.slug=b.slug;`

### W4 — UPDATE `fm-07-olsen-tier-d` — append Olsen voice + CV

- **Why:** include the user-supplied Pythagorean Plato narrative
  (Republic "cut a line unevenly" → φ / 1/φ), the lineage (Kepler →
  Penrose → Shechtman → Kroto → Coldea E₈), the El Naschie golden
  mean number system, and verbatim Binnig/Prigogine endorsement
  letters; plus CV + selected publications.
- **Verify:** `fm-07` body 9973B → 15507B (+5534B), word_count 1335 → 2156,
  sha256 `92bc6fcce0fb… → e2b7274171af…`.
- **Rollback:** `UPDATE ssot_brochure.chapters c SET body_md=b.body_md, sha256=b.sha256 FROM ssot_brochure.fm07_before_olsen_append b WHERE c.slug=b.slug;`

### W5 — UPDATE `fm-01-cover` — rename to GOLDEN CHAIN

- **Why:** TOC was still showing "GOLDEN BRIDGE" (legacy title); the
  brochure has been repositioned as GOLDEN CHAIN throughout cover,
  metadata, and DePIN chapter — the cover row needed to match.
- **What:**
  ```sql
  UPDATE ssot_brochure.chapters SET
    title   = 'GOLDEN CHAIN — Armoured Provenance Layer for DePIN (...)',
    body_md = replace(body_md, '# GOLDEN BRIDGE', '# GOLDEN CHAIN — Armoured Provenance Layer for DePIN')
  WHERE slug='fm-01-cover';
  ```
- **Verify:** new title starts with "GOLDEN CHAIN — ...".
- **Rollback:** `UPDATE ssot_brochure.chapters c SET title=b.title, body_md=b.body_md, sha256=b.sha256 FROM ssot_brochure._fm01_before_rename b WHERE c.slug=b.slug;`

## Safety properties (still upheld)

- No DSNs, tokens, or `pg_dump` output committed to git.
- Every UPDATE has a corresponding per-row snapshot table.
- All chapter SHA-256 fingerprints recomputed server-side via
  `encode(digest(convert_to(body_md,'UTF8'),'sha256'),'hex')`.
- All writes ran inside `BEGIN; … COMMIT;` blocks (single chapter
  changes are still committed atomically).
- This log is the single source of truth for what was written and how
  to undo it.
