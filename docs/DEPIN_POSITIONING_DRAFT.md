
# Armoured Provenance Layer for DePIN — Three Crowns as a Trust Co-Processor

> **Verification rule.** Every external citation is either marked
> `[verified]` (primary source URL fetched and quoted verbatim during
> the build of GOLDEN CHAIN v19, 2026-05-25, content cached in
> `docs/SOURCES_VERIFIED.md`) or omitted. Positioning claims about
> Three Crowns carry explicit `VERIFIED` / `EMPIRICAL FIT` /
> `OPEN CONJECTURE` / `ROADMAP` labels per
> `docs/agent-rules/04-claim-status.md`. UK English throughout.

## 1. The witness, not the racing car

We position the **Three Crowns of TTSKY26b** as a **hardware witness**
for DePIN event provenance — a small, auditable silicon component that
sits **inside an attesting device** and produces a per-event,
per-device, signed packet which an existing DePIN verifier
(IoTeX W3bstream, peaq verify, Chainlink, smart contract) can trust
without trusting the rest of the device firmware.

The chapter uses the single metaphor **witness** throughout; "armoured
courier" / "cash-in-transit" framings used in earlier drafts have been
retired to avoid metaphor fatigue.

## 2. Where the gap actually is (not the gap reviewers will assume)

A naïve reader of the DePIN literature will say: *IoTeX W3bstream,
peaq verify and Chainlink already verify off-chain compute and DePIN
events — what is left?* The honest answer is:

- **W3bstream verifies the off-chain compute step.** It assumes the
  device-side packet is authentic; it does not itself attest the
  silicon that produced it. *[verified, see
  docs.iotex.io/depin/iotex-depin-modules/w3bstream]*
- **peaq verify Tier 1 (Machine-Origin Authentication)** is the layer
  closest to ours. peaq says *"data signed directly by the device's
  private key — highest trust."* It does **not** specify *where the
  private key lives* or *whether the signing engine is open and
  reset-anchored*. *[verified, see docs.peaq.xyz/sdk-reference/javascript/verify/verify]*
- **Chainlink Proof of Reserve** secures **asset reserves**, not
  device-level event provenance. *[verified, see chain.link/proof-of-reserve]*

The gap Three Crowns occupies is **inside peaq Tier 1**: the *physical
guarantee* that the key used to sign was generated, stored, and used
on a publicly-auditable silicon component whose reset behaviour is
mechanically proven. That guarantee is what allows W3bstream / Chainlink
/ peaq verify to be **stronger than they currently are**, not a
replacement for them. We sit **under** their layer, not against it.

## 3. Comparison to shipping DePIN hardware

The chapter cannot ignore competitors who **already** ship
hardware-rooted DePIN devices. We are not first; we are differently
positioned.

| Player | What they ship | Provenance basis | What we add |
|---|---|---|---|
| **Pebble Tracker** (IoTeX) | sensor tracker | proprietary firmware + signing | open-RTL anchor, Coq-checked reset invariant |
| **DIMO Macaron** | vehicle dongle | OBD-II + cloud key custody | reset-anchored on-device witness, no cloud trust assumption |
| **WeatherXM station** | weather kit | per-station signing key | open silicon witness, falsifiable identity |
| **Helium hotspot** | LoRa hotspot | Proof-of-Coverage protocol | Three Crowns is silicon-level, not protocol-level |

We do not compete with these on physical sensor coverage, BOM cost, or
network rewards. We compete on **the falsifiability of the
device-identity claim**.

## 4. The architecture — honest scope

The end-to-end *vision* is the courier pipeline below. The *implemented
slice* (today) is only the silicon anchor; the rest is `ROADMAP`.

```
   Sensor / Machine
        v
   TRIOS device identity            [ROADMAP — PUF-derived secret]
        v
   secure event sealing             [ROADMAP — per-event nonce + timestamp]
        v
   per-event signature              [ROADMAP — NIST Ascon, on-device]
   + 0x47C0 reset-time witness      [VERIFIED — Theorem 36.1, Coq-proven]
        v
   off-chain prover / oracle        [external — W3bstream / peaq Tier 3]
        v
   smart contract reward            [external — on-chain settlement]
```

What is `VERIFIED` today:

- The byte `0x47C0` appears at `{uio_out, uo_out}` immediately on reset,
  in all three Three Crowns ASICs (Phi #4914, Euler #4915, Gamma #4913),
  mechanically proven by Theorem 36.1 in the Coq development.

What is **not yet** implemented (and must not be implied):

- No on-device PUF (Physical Unclonable Function) is fabricated yet.
- No on-device NIST Ascon AEAD/hash engine is fabricated yet.
- No per-event signing pipeline exists in RTL.

This honesty is not a weakness; it is the reason the chapter is
falsifiable. Any reviewer can verify both the present claim
(reproduce the anchor byte on the TT shuttle) and the ROADMAP claims
(track the public PRs that will add PUF, Ascon, signing).

## 5. Threat model — what the witness defends against

| Attack | Three Crowns today | Three Crowns + ROADMAP |
|---|---|---|
| Forged device identity | ⚠️ partial — anchor identifies bitstream, not chip-instance | ✅ PUF-derived per-chip secret |
| Replay of old event | ❌ not defended | ✅ per-event nonce + timestamp window |
| Substitution of event payload | ❌ not defended | ✅ signature over (payload \|\| nonce \|\| device-id) |
| Compromised host firmware | ✅ silicon path bypasses firmware | ✅ same |
| Cloud-side fabrication | ✅ reset anchor cannot be replayed by a cloud service without the silicon | ✅ same |

The honest claim is: **today the witness defends against host
firmware compromise and cloud fabrication; full courier protection
against forged-identity and replay attacks ships with the ROADMAP
items.**

## 6. Standards alignment

The architecture is an instance of **IETF RATS** (RFC 9334
Remote Attestation Procedures architecture, *[verified]*):

- **Attester** — TRIOS-anchored device (sensor + Three Crowns silicon)
- **Evidence** — signed, anchored event packet (ROADMAP)
- **Verifier** — external off-chain prover (W3bstream / peaq Tier 3)
- **Relying Party** — DePIN smart contract paying rewards

RFC 9334: *"Attestation Results may contain a boolean value indicating
compliance or non-compliance with a Verifier's appraisal policy or may
carry a richer set of Claims about the Attester."*

Adjacent open standards we plan to adopt, **not yet implemented**:

- **NIST SP 800-232 (Ascon)** — finalised lightweight cryptography
  standard for constrained devices, *[verified at nist.gov, Aug 2025]*.
  Target AEAD/hash primitive. `ROADMAP`.
- **OpenTitan** — open silicon Root of Trust, *[verified]*. Three Crowns
  is **not** a replacement for OpenTitan; it is a **smaller, narrower
  anchor** suitable where an OpenTitan-scale RoT will not fit. Where
  both can coexist (e.g. an OpenTitan-equipped host gateway plus
  TRIOS-anchored leaf sensors), they compose; they do not compete.

## 7. Claim ledger

| Status | Claim |
|---|---|
| `VERIFIED` | Anchor byte `0x47C0` at `{uio_out, uo_out}` on reset (Theorem 36.1, Coq-proven, mechanically reproducible on TT SKY130). |
| `EMPIRICAL FIT` | Three Crowns projected silicon envelope: ~1 GOPS @ ~50 MHz @ ~1 W (QMTech XC7A100T board). |
| `ROADMAP` | PUF-derived per-device secret. |
| `ROADMAP` | NIST Ascon on-device AEAD/hash engine. |
| `ROADMAP` | Per-event signature `sign(payload \|\| nonce \|\| device-id \|\| timestamp)`. |
| `OPEN CONJECTURE` | The combined `VERIFIED + ROADMAP` stack yields a witness whose Evidence (in IETF RATS terms) is independently falsifiable and reproducible. |
| `NOT CLAIMED` | Replacement for OpenTitan, IoTeX W3bstream, peaq Tier 1, or Chainlink PoR. We sit *under* them. |
| `NOT CLAIMED` | Defence against side-channel attacks (power analysis, EM emission) — that is a separate research programme. |

## 8. Scope — where this design fits and where it does not

**Fits.** Low-power IoT and DePIN leaf devices where the workload is
event-attestation, not heavy compute: weather observation, GNSS
reference reporting, wireless coverage proof, environmental sensors,
and similar. Power budget ≤ 1 W, packet rate ≤ 1000 events/s, packet
payload ≤ 4 kB.

**Does not fit.** High-bandwidth media (Helium video), full
autonomous-vehicle telemetry, or anywhere a heavyweight OpenTitan-class
RoT plus a hardware security module is already required by regulation.
For those, use OpenTitan; we are a smaller component for a smaller niche.

## 9. One-line summary

**Three Crowns: a Coq-proven silicon witness for DePIN event
provenance, sitting under W3bstream / peaq Tier 1.**

## 10. Call to action

- **Reproduce the anchor.** Pull the bitstream for any of Phi
  (TT #4914), Euler (TT #4915), Gamma (TT #4913), apply reset, observe
  `0x47C0` at `{uio_out, uo_out}`. If you cannot, the central
  `VERIFIED` claim of this chapter is falsified and the rest of the
  positioning collapses.
- **Cite this work as.** Vasilev, Pellis, Olsen. *GOLDEN CHAIN — A
  Three-Strand Compendium on φ-Structured Physical Constants*, chapter
  *Armoured Provenance Layer for DePIN*, 2026.
  DOI 10.5281/zenodo.19227877.
- **Engage.** Contact admin@t27.ai for the PUF / Ascon / signing
  ROADMAP timeline and partnership conditions.

## 11. References (all verified during the v19 build)

- IoTeX W3bstream — <https://docs.iotex.io/depin/iotex-depin-modules/w3bstream/>
- peaq verify SDK — <https://docs.peaq.xyz/sdk-reference/javascript/verify/verify>
- Chainlink Proof of Reserve — <https://chain.link/proof-of-reserve>
- IETF RFC 9334 (RATS) — <https://www.rfc-editor.org/rfc/rfc9334.html>
- NIST SP 800-232 (Ascon, Aug 2025) — <https://www.nist.gov/news-events/news/2025/08/nist-finalizes-lightweight-cryptography-standard-protect-small-devices>
- OpenTitan — <https://opentitan.org/documentation/index.html>

