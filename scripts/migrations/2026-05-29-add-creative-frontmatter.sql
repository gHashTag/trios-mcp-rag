-- v2: make 5 creative frontmatter pages unnumbered (\chapter*)
-- by prefixing body_md with `# Title {.unnumbered}` so pipeline takes it as H1

BEGIN;

UPDATE ssot_brochure.chapters
SET body_md = '# Epigraph {.unnumbered}

\thispagestyle{empty}
\vspace*{\fill}
\begin{center}
\begin{minipage}{0.78\textwidth}
\itshape\large

\begin{flushright}
``Geometry has two great treasures: one is the theorem of Pythagoras,\\
the other the division of a line into extreme and mean ratio.\\
The first we may compare to a mass of gold, the second we may call a precious jewel.''

\medskip
\upshape\normalsize --- Johannes Kepler, \emph{Mysterium Cosmographicum} (1596)
\end{flushright}

\vspace{1.2cm}
\itshape\large
\begin{flushright}
``The miracle of the appropriateness of the language of mathematics\\
for the formulation of the laws of physics is a wonderful gift\\
which we neither understand nor deserve.''

\medskip
\upshape\normalsize --- Eugene Wigner, \emph{Comm. Pure Appl. Math.} (1960)
\end{flushright}

\vspace{1.2cm}
\itshape\large
\begin{flushright}
``Not everything that can be counted counts,\\
and not everything that counts can be counted.''

\medskip
\upshape\normalsize --- attributed to William Bruce Cameron (1963)
\end{flushright}

\end{minipage}
\end{center}
\vspace*{\fill}
\clearpage

\thispagestyle{empty}
\vspace*{\fill}
\begin{center}
\begin{minipage}{0.78\textwidth}
\itshape\large

\begin{flushright}
``$\varphi^{2} + \varphi^{-2} = 3.$\\
The golden ratio answers the simplest closure question one can ask of a number:\\
add it to its own inverse-square and obtain an integer.\\
The rest of this book follows from that one line.''

\medskip
\upshape\normalsize --- Strand I, anchor identity, this volume
\end{flushright}

\end{minipage}
\end{center}
\vspace*{\fill}
\clearpage
'
WHERE slug = 'fm-01a-epigraph';

UPDATE ssot_brochure.chapters
SET body_md = '# Dedication {.unnumbered}

\thispagestyle{empty}
\vspace*{\fill}
\begin{center}
\begin{minipage}{0.7\textwidth}
\centering
\itshape\Large

For those who measure twice and claim once.

\vspace{2cm}

\normalsize\upshape
For Stergios, who held the golden angle steady\\
across forty years of fine-structure tables.

\vspace{1cm}

For Scott, who reminded us that $\varphi$ lives\\
at every scale, not only the convenient ones.

\vspace{1cm}

For the silicon, which does not negotiate\\
with our hopes about it.

\vspace{2cm}

\itshape\small
And for the next reader, who will be\\
the one to falsify what we got wrong.

\end{minipage}
\end{center}
\vspace*{\fill}
\clearpage
'
WHERE slug = 'fm-01b-dedication';

UPDATE ssot_brochure.chapters
SET body_md = '# A Letter from the Authors {.unnumbered}

\vspace{0.4cm}

\noindent
Reader,

\vspace{0.4cm}

\noindent
You are holding a book that should not have been possible to write in one volume.

\vspace{0.3cm}

\noindent
On one side sits a forty-year tradition of golden-ratio approaches to the fine-structure constant --- Heyrovska''s golden angle, Sherbon''s geometric prior, Pellis''s hierarchical $\varphi^{-k}$ expansion. On the other side sits a $160 \times 100\ \mu$m square of silicon on TinyTapeout SKY26b, manufactured at SkyWater''s 130\,nm process, in which the bytes \texttt{0x47C0} appear at reset --- not by convention, but as the arithmetic consequence of $\varphi^{2} + \varphi^{-2} = 3$.

\vspace{0.3cm}

\noindent
Between these two sides we have placed a \emph{Bridge}: a symbolic grammar $G_\varphi$, a minimum-description-length (MDL) cost function, and a pre-registered falsification ledger called \textsc{Catalog42}. The Bridge does not claim that $\varphi$ \emph{explains} the constants of Nature. It claims something narrower and testable: that under MDL with a fixed grammar and a frozen prior, the $\varphi$-structured representations of certain constants are shorter than the next-best alternatives by a margin that can be reported, audited, and, if wrong, refuted.

\vspace{0.3cm}

\noindent
We have tried to write this book the way we would want to read it. Every empirical claim carries a status label --- \emph{Verified}, \emph{Empirical fit}, \emph{Open conjecture}, \emph{High-risk}, or \emph{Retracted} --- mapped to the HaluEval and FActScore taxonomies. Every \emph{Open conjecture} carries a one-line falsification path. Every silicon claim points at a Coq-mechanised proof step or is labelled as a projected envelope. Where we disagree among ourselves --- and we do, on at least three points marked in the text --- we say so.

\vspace{0.3cm}

\noindent
If you are a physicist, you will probably want to begin with the prior-art chapter and the $\alpha^{-1}$ reconciliation table. If you are an engineer, begin with the Three Crowns and the DePIN positioning chapter. If you are a referee, begin with the methodology chapter and the adversarial self-critique. A map is on the next page.

\vspace{0.3cm}

\noindent
What you should \emph{not} expect from this book: a closed-form derivation of the Standard Model, a prize-winning announcement, or a promise that $\varphi$ is the secret of the universe. What you should expect: a ledger, an anchor, and a list of ways in which the ledger could be wrong.

\vspace{0.6cm}

\hfill\itshape Dmitrii Vasilev\\
\hfill Stergios Pellis\\
\hfill Scott Olsen\\
\hfill\upshape Ko Samui --- Ioannina --- Iowa\\
\hfill 29 May 2026

\clearpage
'
WHERE slug = 'fm-01c-prologue';

UPDATE ssot_brochure.chapters
SET body_md = '# How to Read This Book {.unnumbered}

\noindent\itshape Four reader profiles, four entry points, one book.\upshape

\vspace{0.6cm}

\noindent
This compendium is structured as \textbf{three strands woven through three silicon crowns}, plus a Bridge that calibrates them. Most readers will not read every page. The reading paths below give a defensible minimum spanning tree through the material for four common profiles.

\vspace{0.6cm}

\noindent\textbf{The Physicist} --- ``Where is the empirical claim, and how is $\alpha^{-1}$ reconciled?''

\begin{itemize}
\setlength\itemsep{0pt}
  \item Prior art chapter --- Heyrovska, Sherbon, Olsen, Coldea et al.
  \item $\alpha^{-1}$ reconciliation table (CODATA, golden-angle, Archimedes).
  \item Consolidated constants catalogue (Vasilev Trinity vs.\ Pellis, 200+ formulas).
  \item $\mu$ (proton-electron mass ratio) Fibonacci-Lucas derivation.
  \item Olsen Tier-D: $\varphi$-cosmology, cross-scale bridge.
\end{itemize}

\vspace{0.4cm}

\noindent\textbf{The Hardware Engineer} --- ``What is on the chip and what does it actually do?''

\begin{itemize}
\setlength\itemsep{0pt}
  \item The Three Crowns of TTSKY26b: Phi, Euler, Gamma.
  \item Armoured Provenance Layer for DePIN --- the Three Crowns as a trust co-processor.
  \item Quantitative positioning: Three Crowns in the silicon-regime taxonomy.
  \item Hardware addendum: Verilog assertions and \texttt{0x47C0} anchor.
\end{itemize}

\vspace{0.4cm}

\noindent\textbf{The Referee} --- ``Where is the methodology, the pre-registration, and the self-critique?''

\begin{itemize}
\setlength\itemsep{0pt}
  \item Methodology and scientific rigour: pre-registered \textsc{Catalog42} protocol.
  \item Adversarial self-critique: devil''s-advocate review of the GOLDEN CHAIN.
  \item Formal MDL and Kolmogorov-complexity foundations.
  \item Paper~1, $\S$10 --- Falsification ledger and out-of-sample tests.
  \item Paper~1, $\S$11 --- Reviewer-risk assessment.
\end{itemize}

\vspace{0.4cm}

\noindent\textbf{The Curious Generalist} --- ``Give me the shortest defensible path through.''

\begin{itemize}
\setlength\itemsep{0pt}
  \item Cover, Epigraph, this letter, ``At a Glance'' (next page).
  \item Strands and Crowns overview chapter.
  \item Self-critique chapter (read what the authors think is weak).
  \item Paper~1, $\S$14 --- Conclusion.
\end{itemize}

\vspace{0.6cm}

\noindent\textbf{Reading conventions.} Claim-status labels (\emph{Verified} / \emph{Empirical fit} / \emph{Open conjecture} / \emph{High-risk} / \emph{Retracted}) appear inline. Every \emph{Open conjecture} carries a one-line falsification path. References are inline with DOIs; the consolidated bibliography is at the end of each Paper.

\clearpage
'
WHERE slug = 'fm-01d-reading-paths';

UPDATE ssot_brochure.chapters
SET body_md = '# GOLDEN CHAIN at a Glance {.unnumbered}

\noindent\itshape One page. Five numbers. Five claim-statuses.\upshape

\vspace{0.6cm}

\noindent\textbf{The five numbers you should remember.}

\vspace{0.3cm}

\begin{center}
\renewcommand{\arraystretch}{1.35}
\begin{tabular}{@{}rl@{}}
$\varphi^{2} + \varphi^{-2} = 3$ & \itshape Strand I anchor identity (exact). \\
\texttt{0x47C0} & \itshape Silicon anchor byte at \{\texttt{uio\_out}, \texttt{uo\_out}\} on reset. \\
$\alpha^{-1} \approx 137.0360$ & \itshape CODATA target reconciled by Strand III. \\
$\mu \approx 1836.15267$ & \itshape Proton-electron mass ratio; Pellis Fibonacci-Lucas form. \\
$\sim 1\ \mathrm{GOPS @}\ {\sim}50\ \mathrm{MHz @}\ {\sim}1\ \mathrm{W}$ & \itshape Three Crowns projected envelope, ternary. \\
\end{tabular}
\end{center}

\vspace{0.6cm}

\noindent\textbf{The five claim-status labels used in this book.}

\vspace{0.3cm}

\begin{center}
\renewcommand{\arraystretch}{1.4}
\begin{tabular}{@{}p{0.22\textwidth}p{0.7\textwidth}@{}}
\textbf{Verified} & Mechanically proven (Coq) or directly measured against a published standard. \\
\textbf{Empirical fit} & Reproduces measured values within stated tolerance; no causal mechanism asserted. \\
\textbf{Open conjecture} & Not yet refuted; carries a written falsification path. Capped here in the absence of external DOI. \\
\textbf{High-risk} & Plausible but contradicted by at least one credible source; flagged in-text. \\
\textbf{Retracted} & Withdrawn after this volume''s freeze; see errata in the project repository. \\
\end{tabular}
\end{center}

\vspace{0.6cm}

\noindent\textbf{What this book is, in one sentence.}\\
A pre-registered, MDL-scored, silicon-anchored ledger of $\varphi$-structured representations of physical constants, with every claim labelled and every \emph{Open conjecture} given a falsification path.

\vspace{0.4cm}

\noindent\textbf{What this book is not.}\\
A closed-form theory of the Standard Model. A claim that $\varphi$ \emph{explains} the constants. A prize announcement.

\vspace{0.6cm}

\noindent\textbf{Reproducibility.}\\
\textsc{Catalog42} freeze: v82, 2026-05-29. DOI: \texttt{10.5281/zenodo.19227877}. Build: \texttt{trios-mcp-rag build-pdf} (pandoc + tectonic). SHA-256 of this PDF is recorded in the build log on the publication branch.

\clearpage
'
WHERE slug = 'fm-01e-at-a-glance';

-- Verify update
SELECT slug, length(body_md) AS len, substring(body_md, 1, 60) AS first_60
FROM ssot_brochure.chapters
WHERE slug IN ('fm-01a-epigraph','fm-01b-dedication','fm-01c-prologue','fm-01d-reading-paths','fm-01e-at-a-glance')
ORDER BY order_key;

COMMIT;
