# Catalog Design

**Claim status:** Verified.

\label{sec:catalog}

### 84 Formats Across 13 Clusters

The `t27` catalog contains 84 formats organized into 13 named clusters.
Table \ref{tab:clusters} shows the cluster names and format counts.  The sum
of counts is exactly 84; this is a continuously enforced catalog invariant
(CI-01, Section \ref{sec:invariants}).

```latex
\begin{table}[ht]
\centering
\caption{The 84 formats across 13 clusters (T1).}
\label{tab:clusters}
\begin{tabular}{llr}
\toprule
\textbf{Cluster} & \textbf{Representative formats} & \textbf{Count} \\
\midrule
IEEE754 binary       & binary16, binary32, binary64, binary128, binary80 & 5 \\
IEEE754 decimal      & decimal32, decimal64, decimal128 & 3 \\
MLLowPrecision       & BF16, TF32, FP8 E4M3, FP8 E5M2, FP8 E3M4, FP6, FP4, NF4 & 8 \\
GoldenFloat          & GF4 through GF256 (phi-anchored variants) & 16 \\
Posit / Unum III     & Posit8, Posit16, Posit32, takum8, takum16, \ldots & 8 \\
OCP MX               & MXFP4, MXFP6\_E2M3, MXFP6\_E3M2, MXFP8\_E4M3, E8M0\_block & 5 \\
LNS                  & LNS8, LNS16 variants & 4 \\
IntegerFixed         & INT2, INT4, INT8, INT16, UINT4, UINT8, UINT16, FXP16 & 8 \\
HistoricalVendor     & IBM hex float, DEC VAX G, Cray single, NVIDIA TF32, \ldots & 10 \\
Theoretical          & E0M7, E7M0, E1M6, E6M1 boundary cases & 4 \\
Compression/scaling  & NF4 block, E8M0 block, SF8, RFP8 & 4 \\
Extended             & binary256, bfloat32, bfloat128 & 3 \\
QuantTuned           & Q-BF16, adaptive-FP8 & 2 \\
\midrule
\textbf{Total} & & \textbf{84} \\
\bottomrule
\end{tabular}
\end{table}
```

### One-Row-Per-Format Schema

Each catalog entry carries the following fields:

- \texttt{name} -- canonical identifier (ASCII, no spaces)
- \texttt{bits} -- total bit width
- \texttt{exp} -- exponent field width in bits
- \texttt{mant} -- mantissa field width in bits (0 for E8M0-style)
- \texttt{bias} -- exponent bias
- \texttt{has\_inf} -- boolean
- \texttt{has\_nan} -- boolean
- \texttt{saturation\_policy} -- \texttt{SatFinite}, \texttt{OvfInf}, or \texttt{OvfNaN}
- \texttt{max\_finite} -- largest representable finite value (f64)
- \texttt{min\_normal} -- smallest positive normal value (f64)
- \texttt{min\_subnormal} -- smallest positive subnormal (f64; \texttt{null} if none)
- \texttt{cluster} -- one of the 13 cluster labels
- \texttt{claim\_status} -- Verified / Empirical\_fit / Open\_conjecture / Risk / Retracted

### Claim-Status Taxonomy

**Verified**: format spec is backed by a published standard (IEEE, OCP) or
by a proof-checked reference (P3109 FLoPS Lean).
**Empirical_fit**: derived by fitting the observed bit layout of a hardware
product without an independently published spec.
**Open_conjecture**: proposed generalization awaiting external validation.
**Risk**: spec reference exists but the catalog encoding may contain errors
not yet caught by the test suite.
**Retracted**: previously included; removed after a conflicting authoritative
source was identified.

### Catalog Invariants

\label{sec:invariants}

Fifteen invariants are checked on every commit.  Selected invariants are listed
in Table \ref{tab:invariants}.

```latex
\begin{table}[ht]
\centering
\caption{15 catalog invariants (CI-enforced) (T2).}
\label{tab:invariants}
\begin{tabular}{cll}
\toprule
\textbf{ID} & \textbf{Invariant} & \textbf{Check} \\
\midrule
CI-01 & Total format count equals 84 & \texttt{sum(cluster\_counts) == 84} \\
CI-02 & No name collisions & \texttt{len(names) == len(set(names))} \\
CI-03 & Bit-width consistency & \texttt{1 + exp + mant == bits} for standard layout \\
CI-04 & Bias range & \texttt{bias <= 2**(exp-1) - 1} \\
CI-05 & Saturation policy present & field not null for every entry \\
CI-06 & Max-finite positive & \texttt{max\_finite > 0} \\
CI-07 & Min-normal $\leq$ max-finite & ordering preserved \\
CI-08 & Cluster label in enum & no unlisted cluster names \\
CI-09 & Claim status in enum & no unlisted claim-status values \\
CI-10 & No format with 0 bits & \texttt{bits >= 2} \\
CI-11 & SHA-256 anchor present & each pack header carries fingerprint field \\
CI-12 & Anchor vector present & each pack contains \texttt{anchor\_*} vector \\
CI-13 & Anchor decodes to 3.0 & \texttt{decode(anchor\_bits) == 3.0} \\
CI-14 & Codegen targets compile & CI matrix runs Python + Rust import tests \\
CI-15 & No duplicate SHA-256 & pack fingerprints are globally unique \\
\bottomrule
\end{tabular}
\end{table}
```

### Codegen Path

A single Jinja2 template tool reads the canonical JSON catalog and emits
per-language output files: Markdown (human-readable table), JSON (API export),
Python dataclasses, Rust structs with `serde` derives, C header
(`#define` constants), and TypeScript enum literals.  All generated
files are committed to the repository at <https://github.com/gHashTag/t27>
and rebuilt on every push via a GitHub Actions matrix.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
