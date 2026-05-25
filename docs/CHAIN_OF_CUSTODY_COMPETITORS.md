# Chain-of-Custody Proof Competitor Map

> Status: market-positioning research note for TRIOS MCP-RAG and future
> SSOT chapter work. Public claims here are framed as `Verified`,
> `Empirical fit`, or `Open conjecture` per
> `docs/agent-rules/04-claim-status.md`.

## Target niche

TRIOS should not be positioned as a high-throughput accelerator or as a
new DePIN L1. The strongest wedge is narrower:

> **Hardware-rooted chain-of-custody proof for physical transactions.**
> A TRIOS witness module seals sensor or machine events at the source,
> binds them to device identity, freshness, context, and local policy,
> then exports evidence to EPCIS, Verifiable Credentials, DePIN
> verifiers, or on-chain settlement systems.

The useful product boundary is:

```text
physical event
  -> TRIOS witness packet
  -> signed custody proof
  -> EPCIS / VC / DePIN verifier
  -> oracle / smart contract / compliance system
```

## Competitor layers

| Layer | Players | Verified capability | TRIOS opening |
| --- | --- | --- | --- |
| Traceability standards | GS1 EPCIS/CBV, W3C Verifiable Credentials, IETF RATS | Define interoperable event, credential, and remote-attestation models. | Treat them as output formats, not competitors. |
| DePIN verification | IoTeX W3bstream, peaq verify, Helium PoC oracles, XYO | Verify machine-origin data, off-chain computation, physical coverage, or proof-of-origin/location. | Provide lower-level signed evidence before their verifier layer. |
| Supply-chain blockchain / graph | OriginTrail DKG, VeChain ToolChain, Hedera TrackTrace | Store or anchor product provenance, credentials, or lifecycle events. | Become the hardware witness that improves the quality of events they ingest. |
| Digital Product Passport / materials | Circulor, Circularise, Minespider, atma.io, Kezzler | Battery, materials, ESG, and product-passport traceability. | Focus on high-assurance handoff events and sensor-sealed evidence. |
| Shipment and cold chain | Tive, Roambee, Sensitech, Controlant | Real-time location/condition monitoring for shipments, pharma, food, and clinical logistics. | Add cryptographic custody packets and DePIN/on-chain export. |
| Anti-counterfeit tags | Scantrust, HID Trusted Tag, Identiv ID-Safe, Wiliot | Secure QR/NFC/RFID/ambient IoT identity, presence, tamper, and traceability. | Move from tag authenticity to signed process/event authenticity. |
| Pharma serialization | TraceLink, SAP ATTP, Antares/rfxcel, MediLedger/Pulse | DSCSA and pharmaceutical track-and-trace, EPCIS exchange, verification services. | Integrate as regulated downstream systems, not initial wedge competitors. |
| Secure elements / RoT | NXP SE050, Microchip ATECC608B, Infineon OPTIGA Trust M, OpenTitan | Hardware key storage, device identity, attestation, and root-of-trust building blocks. | TRIOS must justify itself above commodity secure elements with local rule checks and an auditable 0x47C0 witness role. |

## Direct threats

1. **IoTeX W3bstream** — strongest DePIN verification competitor. It is
   explicitly about verifiable off-chain computation for DePIN and can
   emit proofs to smart contracts.
2. **peaq verify** — strong machine-origin framing. Its Tier 1 language
   overlaps with TRIOS device-origin proof.
3. **XYO** — closest narrative competitor for proof-of-origin,
   proof-of-location, and real-world data assurance.
4. **OriginTrail DKG** — strong enterprise / AI provenance competitor
   because it combines verifiable knowledge assets with supply-chain
   provenance.
5. **Tive / Controlant / Sensitech** — non-Web3 incumbents that already
   move high-value physical data for logistics and pharma.
6. **NXP SE050 / ATECC608B / OPTIGA Trust M** — low-cost component-level
   substitutes if TRIOS is framed as "just device signing."

## Positioning discipline

| Claim status | Statement |
| --- | --- |
| `Verified` | GS1 EPCIS, W3C VC, IETF RATS, IoTeX, peaq, Helium, and secure-element vendors already define parts of the custody-proof stack. |
| `Empirical fit` | TRIOS has a plausible architectural fit as a small witness layer between sensors and DePIN/oracle/compliance systems. |
| `Open conjecture` | The Three Crowns / 0x47C0 anchor can become a differentiated hardware-provenance primitive for real DePIN reward flows. |
| `Not claimed` | TRIOS proves physical truth by itself. |
| `Not claimed` | TRIOS replaces full silicon roots of trust, supply-chain SaaS, or DePIN verifier networks. |

## Recommended wedge

Start with one scenario where custody matters more than throughput:

- battery / critical-minerals handoff,
- pharma cold-chain release,
- EV charging / energy-meter evidence,
- robot / machine service proof,
- secure edge data courier for DePIN validators.

The first product proof should export a compact packet:

```json
{
  "device_id": "public key or DID",
  "event_type": "handoff | measurement | service | charge",
  "timestamp": "freshness-bound time",
  "nonce": "anti-replay value",
  "sensor_digest": "hash of raw or sampled evidence",
  "local_policy_result": "pass | fail | warning",
  "trios_anchor": "0x47C0 witness metadata",
  "signature": "device or module signature"
}
```

## Source links

- GS1 EPCIS/CBV: <https://www.gs1.org/standards/epcis>
- IETF RATS RFC 9334: <https://www.ietf.org/rfc/rfc9334.html>
- W3C Verifiable Credentials 2.0: <https://www.w3.org/news/2025/the-verifiable-credentials-2-0-family-of-specifications-is-now-a-w3c-recommendation/>
- IoTeX W3bstream verification: <https://docs.iotex.io/depin/iotex-depin-modules/w3bstream/w3bstream-depin-verification>
- peaq verify: <https://docs.peaq.xyz/sdk-reference/javascript/verify/verify>
- Helium Proof-of-Coverage: <https://docs.helium.com/iot/proof-of-coverage>
- XYO technologies: <https://docs.xyo.network/about-xyo/proprietary-technologies-and-solutions>
- OriginTrail DKG: <https://docs.origintrail.io/dkg-key-concepts>
- VeChain ToolChain: <https://docs.vetoolchain.com/hc/en-us/articles/6622299409433-Product-Features>
- Hashgraph TrackTrace: <https://www.prnewswire.com/news-releases/the-hashgraph-group-announces-the-launch-of-tracktrace-for-compliance-with-eus-digital-product-passport-dpp-regulation-302694574.html>
- Circulor Battery Passport: <https://circulor.com/articles/circulor-battery-passport>
- Circularise traceability platform: <https://www.circularise.com/>
- Minespider Digital Product Passports: <https://www.minespider.com/>
- Tive visibility: <https://www.tive.com/why-tive>
- Sensitech cold chain: <https://www.sensitech.com/en/solutions/cold-chain/>
- Controlant clinical logistics: <https://www.controlant.com/clinical-trials>
- HID Trusted Tag: <https://www.hidglobal.com/solutions/trusted-tag-services>
- Identiv ID-Safe: <https://identiv.com/product-family/id-safe/>
- TraceLink DSCSA: <https://www.tracelink.com/products/product-orchestration/country-compliance/us-compliance>
- SAP ATTP: <https://help.sap.com/docs/S4_ADV_TRACK_TRACE_PHARMA/b1a2f93e74a449ec9cc9b6a019280ef8/088ccc55614d037ce10000000a44147b.html>
- NXP SE050: <https://www.nxp.com/products/SE050>
- Microchip ATECC608B: <https://www.microchip.com/en-us/product/atecc608b>
- OpenTitan: <https://opentitan.org/documentation/index.html>
