# Conformance Pack Methodology

**Claim status:** Verified.

\label{sec:methodology}

### Shared Row Schema

Every conformance pack is a JSON array of vectors, each row conforming to the
schema shown in Table \ref{tab:schema}.

```latex
\begin{table}[ht]
\centering
\caption{Shared row schema for all conformance packs (T3).}
\label{tab:schema}
\begin{tabular}{lll}
\toprule
\textbf{Field} & \textbf{Type} & \textbf{Description} \\
\midrule
\texttt{name}              & string  & human-readable test-case identifier \\
\texttt{input\_f64}        & number  & input value as a double-precision float \\
\texttt{input\_f64\_hex}   & string  & IEEE 754 hex encoding of the input (f32 or f64) \\
\texttt{<fmt>\_bits\_hex}  & string  & target-format bit pattern, hex \\
\texttt{<fmt>\_bits\_int}  & integer & same bit pattern as an unsigned integer \\
\texttt{decoded\_f64}      & number  & result of decode(encode(input)) \\
\texttt{decoded\_f64\_hex} & string  & IEEE 754 hex encoding of decoded value \\
\texttt{abs\_error}        & number  & $|$input $-$ decoded$|$; always shown (never hidden) \\
\texttt{category}          & string  & zero / normal / subnormal / inf / nan / overflow / \\
                            &         & underflow / rounding / anchor / transcendental \\
\bottomrule
\end{tabular}
\end{table}
```

### Pack Header

In addition to the vector array, each pack file carries a header object with
the following fields:

- Format spec quadruple: $(E, M, \text{bias}, \text{infNaN policy})$
- Saturation policy
- Max-finite value
- SHA-256 self-fingerprint (computed over the canonical JSON serialization)
- \texttt{ml\_dtypes} version anchor
- Anchor identity reference: \texttt{phi\^{}2 + 1/phi\^{}2 = 3 (arXiv:2606.05017)}

### Anchor Vector

Every pack contains at least one vector named `anchor_*` that encodes
the value $3.0$.  The motivation is the identity
```latex
\begin{equation}
  \varphi^{2} + \frac{1}{\varphi^{2}} = 3,
  \label{eq:anchor}
\end{equation}
```
where $\varphi = (1 + \sqrt{5})/2$ is the golden ratio.  This identity is
presented and contextualized in the GoldenFloat preprint [gf_arxiv] as a
numerically grounded $L_2$ anchor.  The value $3.0$ is exactly representable in
all six pack formats (it falls in the normal range with zero mantissa error
for all six layouts), making it a reliable single-line sanity check across packs.

Formally: for any pack format $F$, if $`decode`_F(`encode`_F(3.0))
\neq 3.0$, a fundamental implementation error is present.

### Verification Steps

Each pack is checked by two independent procedures:

1. \textbf{Round-trip self-check.} For each vector: $\texttt{decode}(\texttt{encode}(\texttt{input})) = \texttt{decoded}$, with the stored \texttt{abs\_error} consistent with the deviation.
2. \textbf{Cross-check against ml\_dtypes 0.5.4.} Where a corresponding ml\_dtypes type exists, the pack's bit patterns are compared against the ml\_dtypes encoding of the same inputs.  Every divergence is recorded in the pack header's \texttt{divergences} list and described in this paper.

Honest treatment of absolute error is a non-negotiable design principle.
Every vector where the decoded value differs from the input carries a nonzero
`abs_error`; no value is suppressed or rounded to zero to make match
statistics look better.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
