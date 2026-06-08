# The Six Conformance Packs

**Claim status:** Empirical fit.

\label{sec:packs}

Table \ref{tab:sixpacks} gives a summary of all six packs.

```latex
\begin{table}[ht]
\centering
\caption{Six packs at a glance (T4).}
\label{tab:sixpacks}
\begin{tabular}{llrrll}
\toprule
\textbf{Pack} & \textbf{Layout} & \textbf{Vecs} & \textbf{ml\_dtypes match} &
\textbf{Status} & \textbf{SHA-256 (first 16 hex)} \\
\midrule
GF16          & S1E5M10 phi-anchored & 21 & n/a (no ml\_dtypes equiv.) & LIVE v0.3.1 & see repo \\
MXFP4         & S1E2M1 block element & 12 & n/a & LIVE v0.3.1 &
  \texttt{86c99d6f72375d75} \\
BF16          & S1E8M7 bias=127, RTE & 21 & 21/21 & NEW v0.4.0-pre &
  \texttt{320c1850b4846745} \\
FP8 E4M3      & S1E4M3 bias=7, SatMax & 16 & 15/16 (see Sec.~\ref{sec:discussion}) & NEW v0.4.0-pre &
  \texttt{fff0c30f8e6bee22} \\
FP8 E5M2      & S1E5M2 bias=15, OvfInf & 17 & 17/17 & NEW v0.4.0-pre &
  \texttt{66cd7be1500ec800} \\
E8M0 block    & E8M0 scale-only, no sign & 11 & OCP MX v1.0 aligned & NEW v0.4.0-pre &
  \texttt{b211f1a863f71fd7} \\
\bottomrule
\end{tabular}
\end{table}
```

Full SHA-256 fingerprints (verbatim from the manifest):
- \textbf{GF16}: see repository (SHA-256 not yet pinned in v0.4.0-pre manifest)
- \textbf{MXFP4}: \texttt{86c99d6f72375d751df4c74897904a0a36cff52e8d60cbfef5d58b71625d4b2f}
- \textbf{BF16}: \texttt{320c1850b484674546785791b1c22d76feb4ea748c6669ffb633e5455d822b8a}
- \textbf{FP8 E4M3}: \texttt{fff0c30f8e6bee22b1a7d0e0e1cff65edde9d2b17ebf97dba0539973f0a5e89d}
- \textbf{FP8 E5M2}: \texttt{66cd7be1500ec8003eb5dee7532bb4e954b7bc0084b6f22a75d02f7842f23a56}
- \textbf{E8M0 block}: \texttt{b211f1a863f71fd7c5e02e512efff0255ebcc51521311186e01cb9992e4464bd}

### GF16 -- GoldenFloat 16-bit

\label{sec:pack_gf16}

GF16 is a 16-bit format using layout S1E5M10 with a phi-rotation of the
representable range.  It is described and motivated in the GoldenFloat
preprint [gf_arxiv].  The pack contains 21 vectors covering zero,
normal values, the anchor $3.0$ (encoding the identity
$\varphi^{2} + 1/\varphi^{2} = 3$, Eq. \eqref{eq:anchor}), subnormals, and
overflow behavior.  Because ml_dtypes does not implement a GF16 type, this pack
has no cross-validation partner; its vectors are verified by the round-trip
self-check only.  GF16 has been live in the `tt-lang-t27` PyPI package
since v0.3.1.

### MXFP4 Element -- OCP Microscaling 4-bit

\label{sec:pack_mxfp4}

MXFP4 element uses layout S1E2M1 (1 sign, 2 exponent, 1 mantissa bit) with
saturation-to-finite overflow policy, as specified in OCP MX v1.0 [ocp_mx].
Within a block, 32 such elements share an E8M0 scale factor.  The element pack
covers 12 vectors: the 15 representable finite values plus zero and the
saturation case.  ml_dtypes does not expose an MXFP4 element type at the time
of writing; the pack is verified by round-trip self-check and compared against
the OCP MX v1.0 value table.
SHA-256:
`86c99d6f72375d751df4c74897904a0a36cff52e8d60cbfef5d58b71625d4b2f`.

### BF16 -- Brain Float 16

\label{sec:pack_bf16}

BF16 uses layout S1E8M7 with bias $= 127$, round-to-nearest-even (RTE), and
IEEE 754-style handling of infinity and NaN.  It occupies the upper 16 bits of
an FP32 word, so conversion to/from FP32 is a simple truncation (with
rounding).  The pack contains 21 vectors, including:
- Positive and negative zero
- Positive and negative infinity (preserved exactly)
- Quiet NaN (preserved with payload)
- Smallest positive normal and subnormal
- Largest finite BF16 ($\approx 3.39 \times 10^{38}$)
- Two RTE midpoint cases (round-to-even behavior)
- Overflow of FP32 max into BF16 $+\infty$ (abs\_error $= +\infty$)
- Underflow of FP32 min-subnormal to BF16 $+0$
- Non-exact constants $\varphi$ and $1/\varphi$ with nonzero abs\_error
- The anchor vector at $3.0$ (exact, abs\_error $= 0$)
All 21 vectors match `ml_dtypes.bfloat16` (Google/JAX 0.5.4): 21/21.
SHA-256:
`320c1850b484674546785791b1c22d76feb4ea748c6669ffb633e5455d822b8a`.

BF16 exhibits high inter-vendor agreement; Google bfloat16, Intel BFLOAT16,
ARM BFloat16, and NVIDIA TF32-paired BF16 share the same IEEE 754-style
sub/inf/NaN semantics with round-to-nearest-even on the lower 16 bits of FP32.
No notable divergences were observed in the 21 boundary cases tested.

### FP8 E4M3 -- Eight-bit Float with Four-bit Exponent

\label{sec:pack_fp8e4m3}

FP8 E4M3 uses layout S1E4M3 with bias $= 7$.  In the OCP MX variant (used
here), infinity is replaced by additional finite values, and NaN is encoded as
bit pattern `0x7F` (or `0xFF` for negative).  The format thus
has no $+\infty$, giving a max-finite value of $448.0$.

The pack contains 16 vectors.  15 of 16 match `ml_dtypes.float8_e4m3fn`
exactly.  The single documented divergence is the overflow case for input
$1000.0$, detailed in Table \ref{tab:overflow_gap} and discussed in
Section \ref{sec:discussion}.
SHA-256:
`fff0c30f8e6bee22b1a7d0e0e1cff65edde9d2b17ebf97dba0539973f0a5e89d`.

```latex
\begin{table}[ht]
\centering
\caption{FP8 E4M3 overflow interpretation gap for input $1000.0$ (T5).}
\label{tab:overflow_gap}
\begin{tabular}{lllll}
\toprule
\textbf{Input} & \textbf{Implementation} & \textbf{Bits} & \textbf{Decoded} & \textbf{Policy} \\
\midrule
$1000.0$ & this pack (tt-metal/AMD convention) & \texttt{0x7E} & $448.0$ (max-finite) & saturate-to-max \\
$1000.0$ & ml\_dtypes 0.5.4 (JAX/TPU convention) & \texttt{0x7F} & NaN & overflow-to-NaN \\
\midrule
\multicolumn{5}{l}{\small Both choices are permitted by OCP MX v1.0. See Section~\ref{sec:discussion}.} \\
\bottomrule
\end{tabular}
\end{table}
```

### FP8 E5M2 -- Eight-bit Float with Five-bit Exponent

\label{sec:pack_fp8e5m2}

FP8 E5M2 uses layout S1E5M2 with bias $= 15$ and retains full IEEE 754-style
infinity and NaN.  Max-finite is $57344.0$.  The pack contains 17 vectors
covering the complete boundary suite (zero, normals, subnormals, $\pm\infty$,
NaN, overflow, underflow, RTE midpoints, and the anchor $3.0$).
All 17 vectors match `ml_dtypes.float8_e5m2` exactly: 17/17.
SHA-256:
`66cd7be1500ec8003eb5dee7532bb4e954b7bc0084b6f22a75d02f7842f23a56`.

### E8M0 Block Scale -- OCP Microscaling Scale Format

\label{sec:pack_e8m0}

E8M0 is a scale-only format used as the shared block exponent in OCP MX blocks.
It carries no sign bit and no mantissa -- only 8 exponent bits representing
powers of 2 in the range $[2^{-127}, 2^{127}]$.  The special pattern `0xFF`
encodes NaN (used to indicate an uninitialized or invalid scale).
The pack contains 11 vectors covering representative scale values, the NaN
sentinel, and the anchor $3.0$ (which encodes to the closest representable
power-of-two scale, $2^1 = 2$, with a documented nonzero abs_error).
Vectors were regenerated against `ml_dtypes.float8_e8m0fnu` (Google/JAX
0.5.4) following OCP MX v1.0 semantics.
SHA-256:
`b211f1a863f71fd7c5e02e512efff0255ebcc51521311186e01cb9992e4464bd`.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
