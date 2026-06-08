# Introduction

**Claim status:** Verified.

\label{sec:intro}

Imagine a machinist who needs to fit a component to a lathe specification, but
the measuring ruler in hand uses units that differ subtly from those in the
drawing.  The part may look correct; the divergence only surfaces under load.
The same scenario plays out in ML accelerator firmware: two chips may both claim
``FP8 E4M3 support'', yet differ silently in how they handle the overflow case
for an input such as $1000.0$ -- one saturates to max-finite $448.0$, the other
flips to NaN.  The OCP Microscaling specification [ocp_mx] permits both
choices.  Without a shared bit-exact reference, a ported model may produce
numerically different results that are difficult to isolate.

This paper describes two artifacts designed to serve as that shared ruler.

**Contribution 1: An 84-format numeric catalog..** 
The `t27` catalog enumerates 84 numeric formats across 13 families
(Section \ref{sec:catalog}).  Each entry carries a uniform schema: bit layout,
bias, infinity/NaN policy, saturation policy, max-finite value, min-normal,
min-subnormal, and a claim-status tag (Verified / Empirical_fit /
Open_conjecture / Risk / Retracted).  The catalog is stored as a single source
of truth and cross-compiled to Markdown, JSON, Python, Rust, C, and TypeScript
via a template tool.

**Contribution 2: Six bit-exact conformance packs..** 
The packs (Section \ref{sec:packs}) cover the six formats most commonly seen
in current production hardware and research pipelines: GoldenFloat 16 (GF16),
MXFP4 element, BF16, FP8 E4M3, FP8 E5M2, and E8M0 block scale.
Two packs (GF16 and MXFP4) are already live in the `tt-lang-t27`
PyPI package \mbox{v0.3.1}; the remaining four are introduced in the current
pre-release, available at
<https://github.com/gHashTag/tt-lang-t27/pull/6>.

**What this paper is not..** 
This paper presents no model-accuracy benchmarks, no novel format proposals, and
no performance comparisons between vendors.  Readers seeking FLOP throughput
analysis or quantization accuracy results should consult the separate literature.

**Roadmap..** 
Section \ref{sec:background} surveys the relevant standards landscape.
Section \ref{sec:catalog} describes the catalog design.
Section \ref{sec:methodology} defines the conformance pack methodology.
Section \ref{sec:packs} presents each of the six packs in turn.
Section \ref{sec:p3109} provides an IEEE P3109 cross-walk.
Section \ref{sec:discussion} discusses the interpretation gap as a design feature.
Section \ref{sec:repro} covers reproducibility and provenance.
Section \ref{sec:future} outlines future work.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
