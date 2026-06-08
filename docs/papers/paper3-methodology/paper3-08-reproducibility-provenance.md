# Reproducibility and Provenance

**Claim status:** Verified.

\label{sec:repro}

### Source Repositories

- \textbf{gHashTag/t27} (\url{https://github.com/gHashTag/t27}): the single source of truth (SSOT) for the catalog and Tier-1 conformance packs. All JSON catalog files, pack files, invariant checks, and codegen templates live here.
- \textbf{gHashTag/tt-lang-t27} (\url{https://github.com/gHashTag/tt-lang-t27}): PyPI mirror.  Version 0.3.1 is live on PyPI (GF16 and MXFP4 packs included).  Version 0.4.0-pre, adding the four new packs described in this paper, is available in \href{https://github.com/gHashTag/tt-lang-t27/pull/6}{PR~\#6}.
- \textbf{gHashTag/tt-trinity-corona} (\url{https://github.com/gHashTag/tt-trinity-corona}): Tier-2 silicon oracle context for post-silicon audit on GF180MCU; one-line mention here for completeness.

### Ground-Truth Tool

The primary oracle for all cross-validation is `ml_dtypes` 0.5.4
[mldtypes] (Google/JAX), available at
<https://github.com/jax-ml/ml_dtypes>.  The specific types used are:
`ml_dtypes.bfloat16`, `ml_dtypes.float8_e4m3fn`,
`ml_dtypes.float8_e5m2`, and `ml_dtypes.float8_e8m0fnu`.

### Anchor Fingerprint

The anchor identity $\varphi^{2} + 1/\varphi^{2} = 3$ (Eq. \eqref{eq:anchor}),
as formalized in the GoldenFloat preprint [gf_arxiv], has the following
canonical SHA-256 fingerprint:
\begin{center}
`218403e344779c890f302ad2c70af21fb765060dd794d793c7eacc1ef8f80e6b`
\end{center}
This fingerprint covers the canonical UTF-8 encoding of the identity string and
serves as an out-of-band check that the correct anchor paper is being cited.

### Pack Provenance Table

Table \ref{tab:provenance} lists the repository path, branch/PR, and full
SHA-256 for each pack.

```latex
\begin{table}[ht]
\centering
\caption{Pack-to-provenance mapping (T7).}
\label{tab:provenance}
\begin{tabular}{lllp{5.5cm}}
\toprule
\textbf{Pack} & \textbf{Repo} & \textbf{Branch / PR} & \textbf{Full SHA-256} \\
\midrule
GF16 & gHashTag/t27 & \texttt{main} (v0.3.1) & see repo (not pinned in v0.4.0-pre manifest) \\
MXFP4 & gHashTag/t27 & \texttt{main} (v0.3.1) &
  \texttt{86c99d6f72375d751df4c74897904a0a36cff} \newline \texttt{52e8d60cbfef5d58b71625d4b2f} \\
BF16 & gHashTag/t27 & PR~\#6 (v0.4.0-pre) &
  \texttt{320c1850b484674546785791b1c22d76feb4} \newline \texttt{ea748c6669ffb633e5455d822b8a} \\
FP8 E4M3 & gHashTag/t27 & PR~\#6 (v0.4.0-pre) &
  \texttt{fff0c30f8e6bee22b1a7d0e0e1cff65edde9} \newline \texttt{d2b17ebf97dba0539973f0a5e89d} \\
FP8 E5M2 & gHashTag/t27 & PR~\#6 (v0.4.0-pre) &
  \texttt{66cd7be1500ec8003eb5dee7532bb4e954b7} \newline \texttt{bc0084b6f22a75d02f7842f23a56} \\
E8M0 block & gHashTag/t27 & PR~\#6 (v0.4.0-pre) &
  \texttt{b211f1a863f71fd7c5e02e512efff0255ebc} \newline \texttt{c51521311186e01cb9992e4464bd} \\
\bottomrule
\end{tabular}
\end{table}
```

### Manifest

The file `MANIFEST_v0.4.0-pre.json` in the `gHashTag/t27`
repository records all six pack SHA-256 values, the ml_dtypes version anchor,
and the P3109 alignment reference in a single machine-readable document.
Downstream consumers can verify pack integrity by recomputing the SHA-256 of
the canonical JSON file and comparing against the manifest entry.

## References {.unnumbered}

_Inline citations resolved in the paper-level bibliography (see Reproducibility section)._
