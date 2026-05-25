# GOLDEN CHAIN — Armored Provenance Layer for DePIN

> **Status:** Draft — proposed new frontmatter / positioning chapter.
> **Claim discipline:** Verified citations carry inline source link; positioning
> claims about TRIOS Three Crowns are labelled `[OPEN CONJECTURE]` or
> `[EMPIRICAL FIT]` per `docs/agent-rules/04-claim-status.md`.
> **Market map:** see `docs/CHAIN_OF_CUSTODY_COMPETITORS.md` for the
> competitor layer analysis behind this positioning.

## 1. Reframe

We are **not** positioning the Three Crowns of TTSKY26b as high-throughput
inference accelerators. We are positioning them as a **secure provenance
co-processor for DePIN**: a small, auditable silicon witness that

1. accepts physical data from a device or sensor,
2. proves that the event came from the claimed origin and is fresh,
3. signs / hashes a verifiable attestation,
4. forwards the attestation to a DePIN verifier, oracle, or smart contract,
5. helps answer the only question that matters for any DePIN reward:
   *was this a real physical event, or a synthetic one?*

The metaphor is not a racing car. It is an **armoured cash-in-transit van**:
not the fastest vehicle, but the one that can be trusted to move value
across an untrusted street without anything being added, removed, or replaced.

## 2. Why this is the right gap to occupy

The DePIN literature converges on a single problem: physical-machine data
must be verifiable before on-chain token economies can be trusted.

- **IoTeX W3bstream (verified).** IoTeX states the problem directly:
  *"the core logic of DePIN projects, specifically the logic that triggers
  on-chain token economies, is not verifiable by anyone and thus not
  trusted."* W3bstream is positioned as an *"off-chain verifiable compute
  protocol designed by IoTeX"* that mitigates *"self-dealing, lazy providers,
  and malicious responses."*
  [`docs.iotex.io/depin/iotex-depin-modules/w3bstream/w3bstream-depin-verification`](https://docs.iotex.io/depin/iotex-depin-modules/w3bstream/w3bstream-depin-verification)

- **peaq verify tiers (verified).** peaq's SDK splits verification into
  three tiers:
  - *Tier 1 — Machine-Origin Authentication:* data signed directly by the
    device's private key. Highest trust.
  - *Tier 2 — Pattern Matching:* incoming data matched against known
    device patterns.
  - *Tier 3 — Oracle-Backed:* validated via oracle (residual trust risk).
  [`docs.peaq.xyz/sdk-reference/javascript/verify/verify`](https://docs.peaq.xyz/sdk-reference/javascript/verify/verify)

- **Helium Proof-of-Coverage (open conjecture — URL).** Helium's IoT
  subnet uses Proof-of-Coverage to attest that hotspots are physically
  providing wireless coverage at a claimed location. The original
  `docs.helium.com/iot/proof-of-coverage` path has been reorganised;
  the canonical reference is via the current IoT subnet docs index.

## 3. Where Three Crowns fits — the *armoured courier* role

The Three Crowns are **not** competing with peaq/IoTeX/Solana for L1 TPS.
They sit **before** the smart contract, and produce the small, signed,
provenance-bound packet that those higher-layer protocols verify.

```text
   Sensor / Machine
        │
        ▼
   TRIOS device identity            ─── machine-origin (peaq Tier 1)
        │
        ▼
   secure event sealing             ─── timestamp, nonce, epoch freshness
        │
        ▼
   hash + signature
   + 0x47C0 reset-time witness      ─── hardware provenance anchor
        │
        ▼
   optional local rule check        ─── pre-prover gate
        │
        ▼
   off-chain prover / oracle        ─── W3bstream / Tier 3 verify
        │
        ▼
   smart contract reward            ─── on-chain settlement
```

The role of `0x47C0` here is **not** "magic physics". It is the
**hardware provenance anchor** [VERIFIED][^anchor]: a reset-time
silicon witness that a packet actually flowed through a specific,
publicly-auditable hardware contour, not through a server-side fake.

[^anchor]: Theorem 36.1 of the compendium, `Three Crowns of TTSKY26b`
    chapter; the anchor byte at `{uio_out, uo_out}` on reset is the only
    byte-level property that this brochure claims as `VERIFIED` in the
    hardware sense.

## 4. Standards alignment

The architecture is a direct instance of IETF RATS:

- **Attester** → the TRIOS device (sensor + Three Crowns silicon)
- **Evidence** → the signed, anchored event packet
- **Verifier** → W3bstream-style off-chain prover (or peaq oracle)
- **Relying Party** → the DePIN smart contract paying rewards

IETF RFC 9334 (Remote Attestation Procedures architecture) defines these
roles canonically [^rats]. The output of the Verifier is **Attestation
Results** that *"may contain a boolean value indicating compliance or
non-compliance with a Verifier's appraisal policy or may carry a richer
set of Claims about the Attester."* [verbatim from RFC 9334]

Two adjacent technical references that this proposal slots into without
contradiction:

- **NIST SP 800-232 (Ascon)** — finalised lightweight cryptography standard
  for resource-constrained devices [^ascon]. Suitable as the AEAD/hash
  primitive on the device side of the courier.
- **OpenTitan** — open silicon Root of Trust project [^opentitan]. Three
  Crowns' role is adjacent but narrower: a *witness*, not a full RoT —
  we do not claim to replace OpenTitan.

[^rats]: [RFC 9334 — Remote ATtestation procedureS Architecture](https://www.rfc-editor.org/rfc/rfc9334.html)
[^ascon]: [NIST finalizes lightweight cryptography standard, Aug 2025](https://www.nist.gov/news-events/news/2025/08/nist-finalizes-lightweight-cryptography-standard-protect-small-devices)
[^opentitan]: [OpenTitan documentation](https://opentitan.org/documentation/index.html)

## 5. Claim discipline — what we will and will not say

| Status | Claim |
|---|---|
| `VERIFIED` | The anchor byte `0x47C0` appears at `{uio_out, uo_out}` on reset (Theorem 36.1, Coq-proven). |
| `EMPIRICAL FIT / PROJECTED` | Three Crowns silicon target: ~1 GOPS @ ~50 MHz @ ~1 W (QMTech XC7A100T projection). |
| `OPEN CONJECTURE` | Three Crowns can serve as a hardware provenance anchor in a DePIN armoured courier role. |
| **NOT CLAIMED** | "Faster than a GPU" |
| **NOT CLAIMED** | "Validates the whole DePIN network" |
| **NOT CLAIMED** | "Proves physical truth" |
| **NOT CLAIMED** | Replacement for a full silicon root-of-trust (OpenTitan-class). |

## 6. One-sentence summary for the cover / abstract

> The Three Crowns of TTSKY26b are not positioned as high-throughput
> inference accelerators; they are positioned as an **armoured provenance
> layer for DePIN** — a small, auditable silicon witness that seals
> physical-machine data, preserves custody, and produces verifiable
> evidence before off-chain provers or smart contracts trigger rewards.

## 7. Open questions before SSOT write

Writing this to `ssot_brochure.chapters` requires explicit confirmation per
`docs/agent-rules/03-safety-railway-postgres.md`. Before doing so:

1. **Insert as new chapter, or amend existing front-matter chapter?**
   Candidates for amendment: `fm-01-cover`, `fm-06-three-crowns`, or
   a new `fm-13-depin-positioning` with `order_key` just below the cover.
2. **Cover subtitle update?** Current cover subtitle reads:
   *"A Three-Strand Compendium on φ-Structured Physical Constants."*
   Proposed addition:
   *"... and an Armoured Provenance Layer for DePIN."*
3. **Helium PoC citation** — should we link the current IoT subnet docs
   index, or omit the bullet entirely until a stable URL is found?
