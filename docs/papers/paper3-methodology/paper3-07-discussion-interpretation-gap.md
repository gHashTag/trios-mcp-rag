# Discussion: The Interpretation Gap as Ruler Value

**Claim status:** Empirical fit.

\label{sec:discussion}

A conformance suite earns its keep not when all vectors match, but when it
exposes a divergence that would otherwise be invisible.  The FP8 E4M3 overflow
case (input $= 1000.0$) is precisely such a case.

The OCP MX v1.0 specification [ocp_mx] states that for inputs exceeding
max-finite ($448.0$ for E4M3), implementations may either saturate to max-finite
or produce NaN.  Two mature, production-quality implementations make different
choices:

- \textbf{tt-metal (Tenstorrent) / AMD convention}: saturate to max-finite.  Bit pattern \texttt{0x7E}, decoded value $448.0$. This pack adopts this convention.
- \textbf{JAX/TPU convention (ml\_dtypes 0.5.4)}: overflow to NaN. Bit pattern \texttt{0x7F}, decoded value NaN.

Neither choice is a bug.  Both are compliant with OCP MX v1.0.  The divergence
is a documented spec-permitted interpretation gap.

The practical implication is significant for compiler and test-harness
authors.  Any cross-vendor port of an FP8 E4M3 computation must either:
(a) select one policy explicitly and document it, or
(b) carry both vectors in its golden-reference test suite, accepting that
overflow-range inputs will produce differing results on different hardware.

This is precisely what a conformance pack is designed to expose.  A test suite
that compares only ``do the outputs match on this hardware?'' would never see
this divergence -- both implementations pass their own tests.  A shared bit-exact
reference makes the gap visible.

Honesty norm: every vector in every pack where the decoded value differs from
the input carries a nonzero `abs_error`.  Overflow to $\pm\infty$ shows
`abs_error = Inf`; underflow to zero shows the actual magnitude of the
underflowed value.  No abs_error field is suppressed or rounded to zero to
improve match statistics.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
