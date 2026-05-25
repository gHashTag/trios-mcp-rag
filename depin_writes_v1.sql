-- ============================================================
-- TRIOS DePIN positioning — SSOT writes plan v1
-- Database: Railway Postgres (ssot_brochure schema)
-- Date: 2026-05-25
-- Safety: backup first, dry-run before commit, single transaction
-- Author: agent (Claude Code) under explicit user direction
-- ============================================================

-- ---------- STEP 0: BACKUP (always run first) ----------
CREATE TABLE IF NOT EXISTS ssot_brochure.chapters_backup_20260525_depin
  AS SELECT * FROM ssot_brochure.chapters;

-- Verify backup row count matches source:
SELECT
  (SELECT count(*) FROM ssot_brochure.chapters)             AS source_rows,
  (SELECT count(*) FROM ssot_brochure.chapters_backup_20260525_depin) AS backup_rows;

-- ---------- STEP 1: INSERT new DePIN positioning chapter ----------
-- order_key=65 places it right after fm-06-three-crowns (60) and
-- before fm-07-olsen-tier-d (70) — so DePIN role is read immediately
-- after the silicon anchor chapter that establishes 0x47C0.

BEGIN;

INSERT INTO ssot_brochure.chapters
  (slug, kind, order_key, title, body_md, illustration_url, word_count)
VALUES (
  'fm-13-depin-positioning',
  'frontmatter',
  65,
  'Armoured Provenance Layer for DePIN — Three Crowns as a Trust Co-Processor',
$BODY$# Armoured Provenance Layer for DePIN — Three Crowns as a Trust Co-Processor

> **Claim discipline.** Citations to DePIN literature are *verified* against
> primary docs. Positioning of the Three Crowns of TTSKY26b is presented as
> `OPEN CONJECTURE` per `docs/agent-rules/04-claim-status.md`. No throughput
> or "fastest chip" claim is made anywhere in this section.

## 1. Reframe

The Three Crowns of TTSKY26b (Phi · Euler · Gamma) are **not** positioned as
high-throughput inference accelerators. They are positioned as a **secure
provenance co-processor for DePIN**: a small, auditable silicon witness that

1. accepts physical data from a device or sensor,
2. proves the event came from the claimed origin and is fresh,
3. signs / hashes a verifiable attestation,
4. forwards it to a DePIN verifier, oracle, or smart contract,
5. helps answer the only question that matters for any DePIN reward —
   *was this a real physical event, or a synthetic one?*

The working metaphor is not a racing car. It is an **armoured
cash-in-transit van** — not the fastest vehicle, but the one that can be
trusted to move value across an untrusted street without anything being
added, removed, or replaced.

## 2. Why this is the right gap to occupy

The DePIN literature converges on a single problem: physical-machine data
must be verifiable before on-chain token economies can be trusted.

- **IoTeX W3bstream.** IoTeX states the problem verbatim: *"the core logic
  of DePIN projects, specifically the logic that triggers on-chain token
  economies, is not verifiable by anyone and thus not trusted."* W3bstream
  is described as an *"off-chain verifiable compute protocol designed by
  IoTeX"* that mitigates *"self-dealing, lazy providers, and malicious
  responses."* (`docs.iotex.io/depin/iotex-depin-modules/w3bstream/w3bstream-depin-verification`)

- **peaq verify tiers.** peaq's SDK splits verification into three tiers:
  - *Tier 1 — Machine-Origin Authentication:* data signed directly by the
    device's private key. Highest trust.
  - *Tier 2 — Pattern Matching:* incoming data matched against known
    device patterns.
  - *Tier 3 — Oracle-Backed:* validated via oracle (residual trust risk).

  (`docs.peaq.xyz/sdk-reference/javascript/verify/verify`)

- **Helium Proof-of-Coverage.** Helium's IoT subnet uses Proof-of-Coverage
  to attest that hotspots physically provide wireless coverage at a
  claimed location. (Helium IoT subnet documentation; canonical path
  reorganised in 2025.)

## 3. Where Three Crowns fits — the *armoured courier* role

The Three Crowns are **not** competing with peaq, IoTeX, Solana, or any
L1 for TPS. They sit **before** the smart contract and produce the small,
signed, provenance-bound packet that those higher-layer protocols verify.

```text
   Sensor / Machine
        ↓
   TRIOS device identity            -- machine-origin (peaq Tier 1)
        ↓
   secure event sealing             -- timestamp, nonce, epoch freshness
        ↓
   hash + signature
   + 0x47C0 reset-time witness      -- hardware provenance anchor
        ↓
   optional local rule check        -- pre-prover gate
        ↓
   off-chain prover / oracle        -- W3bstream / Tier 3 verify
        ↓
   smart contract reward            -- on-chain settlement
```

The role of `0x47C0` here is **not** "magic physics". It is the
**hardware provenance anchor** [VERIFIED]: a reset-time silicon witness
that a packet actually flowed through a specific, publicly-auditable
hardware contour (Theorem 36.1, Coq-proven), not through a server-side
fake.

## 4. Standards alignment — IETF RATS

The architecture is a direct instance of the IETF Remote Attestation
Procedures (RATS) architecture, RFC 9334:

- **Attester** → the TRIOS device (sensor + Three Crowns silicon)
- **Evidence** → the signed, anchored event packet
- **Verifier** → off-chain prover (e.g. W3bstream) or oracle (peaq Tier 3)
- **Relying Party** → the DePIN smart contract paying rewards

RFC 9334 defines Attestation Results as values that *"may contain a
boolean value indicating compliance or non-compliance with a Verifier's
appraisal policy or may carry a richer set of Claims about the Attester."*
(verbatim from RFC 9334)

## 5. Adjacent technical references

- **NIST SP 800-232 (Ascon)** — finalised lightweight cryptography
  standard for resource-constrained devices including *"IoT devices,
  RFID tags, and medical implants"* (NIST, August 2025). Suitable as the
  AEAD/hash primitive on the device-side of the courier.

- **OpenTitan** — *"an open source silicon Root of Trust (RoT) project."*
  The Three Crowns' role is adjacent but **narrower**: a witness, not a
  full RoT. We do not claim to replace OpenTitan.

## 6. Claim discipline

| Status | Claim |
|---|---|
| `VERIFIED` | The anchor byte `0x47C0` appears at `{uio_out, uo_out}` on reset (Theorem 36.1, Coq-proven). |
| `EMPIRICAL FIT / PROJECTED` | Three Crowns silicon target: ~1 GOPS @ ~50 MHz @ ~1 W (QMTech XC7A100T projection). |
| `OPEN CONJECTURE` | Three Crowns can serve as a hardware provenance anchor in a DePIN armoured-courier role. |
| **NOT CLAIMED** | "Faster than a GPU." |
| **NOT CLAIMED** | "Validates the whole DePIN network." |
| **NOT CLAIMED** | "Proves physical truth." |
| **NOT CLAIMED** | Replacement for a full silicon root-of-trust (OpenTitan-class). |

## 7. One-sentence positioning

> The Three Crowns of TTSKY26b are not positioned as high-throughput
> inference accelerators; they are positioned as an **armoured provenance
> layer for DePIN** — a small, auditable silicon witness that seals
> physical-machine data, preserves custody, and produces verifiable
> evidence before off-chain provers or smart contracts trigger rewards.

## 8. References

- IoTeX W3bstream DePIN verification:
  `https://docs.iotex.io/depin/iotex-depin-modules/w3bstream/w3bstream-depin-verification`
- peaq verify SDK:
  `https://docs.peaq.xyz/sdk-reference/javascript/verify/verify`
- IETF RATS Architecture (RFC 9334):
  `https://www.rfc-editor.org/rfc/rfc9334.html`
- NIST lightweight cryptography (Ascon, SP 800-232):
  `https://www.nist.gov/news-events/news/2025/08/nist-finalizes-lightweight-cryptography-standard-protect-small-devices`
- OpenTitan documentation:
  `https://opentitan.org/documentation/index.html`
- Helium IoT subnet documentation:
  `https://docs.helium.com/iot/`
$BODY$,
  NULL,  -- illustration_url: none yet (could be the three-rings golden chain)
  900     -- word_count (approximate)
);

-- ---------- DRY-RUN VERIFICATION before commit ----------
-- Inspect what would be inserted:
SELECT slug, kind, order_key, title, length(body_md) AS body_len, word_count
FROM ssot_brochure.chapters
WHERE slug = 'fm-13-depin-positioning';

-- Confirm ordering is correct (should appear between fm-06 and fm-07):
SELECT slug, order_key, title
FROM ssot_brochure.chapters
WHERE kind = 'frontmatter'
ORDER BY order_key;

-- If everything looks right:
COMMIT;
-- Otherwise:
-- ROLLBACK;

-- ---------- ROLLBACK plan ----------
-- If the chapter must be removed:
-- DELETE FROM ssot_brochure.chapters WHERE slug = 'fm-13-depin-positioning';
--
-- Full restore from backup:
-- TRUNCATE ssot_brochure.chapters;
-- INSERT INTO ssot_brochure.chapters
--   SELECT * FROM ssot_brochure.chapters_backup_20260525_depin;
