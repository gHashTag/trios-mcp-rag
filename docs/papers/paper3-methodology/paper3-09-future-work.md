# Future Work

**Claim status:** Open conjecture.

\label{sec:future}

### Track 2: Full 84-Pack Suite

The six packs in this paper cover the formats most immediately relevant to
production ML hardware.  Track 2 (target Q3 2026) will extend coverage to
all 84 catalog formats for which reference implementations are available,
including the remaining MLLowPrecision entries (FP6, FP4, NF4),
Posit/Unum III types, and GoldenFloat variants GF4 through GF256.

### Operation-Layer Conformance

The current suite covers the representation layer only.  Track 2 will add
operation-layer vectors aligned with the P3109 `StandardOperations.yaml`
subset, beginning with NearestTiesToEven rounding for Add, Multiply, and FMA
across all six current formats.  This will allow compiler and hardware teams to
validate not only that they encode/decode correctly, but that their arithmetic
operations agree with the standard at the bit level.

### Round-Trip Fuzzing

A property-based fuzzer will complement the hand-crafted boundary vectors.
The fuzzer will generate random FP32 inputs, apply encode/decode for each
format, and assert the round-trip property and abs_error consistency.  This
is particularly valuable for formats with complex saturation behavior.

### Open Invitations

Maintainers of ml_dtypes, OCP MX, IEEE P3109, IREE, vllm, llama.cpp, and
onnxruntime are invited to consume the catalog as a cross-walk substrate,
validate the pack vectors against their implementations, and report divergences
as GitHub issues on `gHashTag/t27`.  Any new divergence found is a
feature of the ruler, not a failure of the suite.

The conformance packs, catalog schema, and codegen templates are open-licensed
with the intent that they become a shared community resource for vendor-neutral
numeric format registry work.
