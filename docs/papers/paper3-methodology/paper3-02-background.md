# Background and Prior Work

**Claim status:** Verified.

\label{sec:background}

### Floating-Point Standards

IEEE 754-2019 [ieee754] defines binary interchange formats (binary16,
binary32, binary64, binary128) and the rounding, overflow, and NaN rules that
govern them.  BF16 (brain float 16) is not in the 2019 revision; it arose
informally at Google Brain and is now supported across Intel, AMD, ARM, and
NVIDIA hardware, sharing the exponent range of FP32 (8 exponent bits, bias
$= 127$) with a 7-bit mantissa.

The OCP Microscaling (MX) specification v1.0 [ocp_mx] introduces block
formats in which groups of 32 elements share a common E8M0 scale factor.
The element types include MXFP4 (S1E2M1), MXFP6 (E2M3 and E3M2), MXFP8 (E4M3
and E5M2), and MXINT8.  OCP MX explicitly permits two overflow policies for
FP8 E4M3: saturation to max-finite (used by the tt-metal and AMD implementations)
and overflow to NaN (used by JAX/TPU).

IEEE P3109 [p3109_interim] is an active working group standardizing
8-bit and 4-bit floating-point formats for AI workloads.  Its v3.2.0 Interim
Report defines Binary8p3se and Binary4p1sf (among others) and a
`StandardOperations.yaml` catalogue of approximately 80 operations
across seven categories.

### Existing Reference Implementations

**ml_dtypes** [mldtypes] (Google/JAX) is a Python/C++ library
offering reference implementations of `bfloat16`,
`float8_e4m3fn`, `float8_e5m2`, `float8_e8m0fnu`,
and several other formats.  It is the ground-truth oracle used throughout this
work.

**P3109 FLoPS** [flops_lean] is a Lean 4 formalization of the P3109
semantics, providing proof-checked coverage of key operations.

**torch.float8** (PyTorch) and **jax.dtypes** expose FP8 types at
the framework level but do not publish bit-vector test suites independent of
hardware execution.

**MX evaluation** studies [mx_eval] measure accuracy impact of
microscaling quantization in transformer workloads.

### The Gap

No single vendor-neutral artifact currently covers FP8 E4M3, FP8 E5M2, BF16,
MXFP4 element, GoldenFloat 16, and E8M0 block scale in one schema with:
(a) bit-exact encode/decode vectors, (b) SHA-256-anchored provenance, (c) 
explicit documentation of each divergence from the reference implementation,
and (d) a human-readable cross-walk to IEEE P3109.  This work fills that
registry gap.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
