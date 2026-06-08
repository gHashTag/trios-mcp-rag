# IEEE P3109 Cross-Walk

**Claim status:** Open conjecture.

\label{sec:p3109}

IEEE P3109 [p3109_interim] is an active working group standardizing
floating-point arithmetic for AI applications.  Its v3.2.0 Interim Report
defines a family of configured formats parameterized by $(E, M, \text{saturation})$.

Table \ref{tab:p3109} maps the six packs to P3109 v3.2.0 configured formats.

```latex
\begin{table}[ht]
\centering
\caption{P3109 v3.2.0 cross-walk for the six packs (T6).}
\label{tab:p3109}
\begin{tabular}{lllll}
\toprule
\textbf{Our format} & \textbf{P3109 name} & \textbf{Match} & \textbf{Key difference} & \textbf{Pack} \\
\midrule
FP8 E4M3  & Binary8p3se & Close & Saturation: ours SatMax vs. P3109 OvfInf;
                                   finite-only NaN encoding & \texttt{fp8\_e4m3} \\
MXFP4 element & Binary4p1sf & Direct & Block structure orthogonal; element matches & \texttt{mxfp4} \\
GF16      & (none)       & No match & P3109 does not address 16-bit phi-anchored formats & \texttt{gf16} \\
BF16      & (none)       & No match & P3109 focuses on 4/8-bit; BF16 is 16-bit & \texttt{bf16} \\
FP8 E5M2  & (none)       & No match & Binary8p2se would correspond but is absent in v3.2.0 & \texttt{fp8\_e5m2} \\
E8M0 block & (none)      & Orthogonal & P3109 does not define a scale-only format & \texttt{e8m0\_block} \\
\bottomrule
\end{tabular}
\end{table}
```

### Direct Matches

**Binary8p3se $\leftrightarrow$ FP8 E4M3.**
P3109 Binary8p3se specifies S1E4M3 with OvfInf saturation.  The OCP MX v1.0
FP8 E4M3 variant used in this pack employs SatMax instead.  The difference is
exactly the overflow interpretation gap documented in Table \ref{tab:overflow_gap}.
Aside from this saturation policy choice, the bit layouts and bias are identical.

**Binary4p1sf $\leftrightarrow$ MXFP4 element.**
P3109 Binary4p1sf specifies S1E2M1 with SatFinite -- identical to the MXFP4
element layout in OCP MX v1.0.  The only structural difference is that OCP MX
wraps elements in 32-element blocks sharing an E8M0 scale factor, a block
dimension that P3109 does not address in v3.2.0.

### Partial and Non-Matches

FP8 E5M2 would map to a hypothetical Binary8p2se, which is absent from P3109
v3.2.0 Profiles.  GF16 and BF16 are outside the 4/8-bit scope that P3109
currently addresses.  E8M0 is a scale-only format orthogonal to P3109's
representation layer.

### Operational Coverage

P3109's `StandardOperations.yaml` enumerates approximately 80 operations
across seven categories: Classification (8), Comparison (7), Extrema
(10+), Projection rounding (6 modes), Math arithmetic (10), Math
transcendental ($\approx$25), and Block operations (40+).

The current suite (v0.1) covers only the _representation layer_ --
encode/decode bit-exactness.  Track 2 (target Q3 2026) will extend coverage to
the operation layer, at minimum NearestTiesToEven rounding for Add, Multiply,
and FMA across all six formats.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
