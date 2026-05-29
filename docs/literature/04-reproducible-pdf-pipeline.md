## Track 4 — Reproducible Scholarly PDF Pipelines

### References

1. **Pandoc official documentation (MacFarlane et al., continuously
   maintained)**
   [pandoc.org](https://pandoc.org).
   The authoritative reference for the Markdown → LaTeX → PDF path. Covers
   `--pdf-engine=tectonic`, template partials, figure environment options,
   `fig-pos` specifiers, and BibTeX/CSL citation integration.

2. **MacFarlane, J. (2020) — "Pandoc for TeXnicians" (TUG 2020 talk)**
   [YouTube TUG 2020](https://www.youtube.com/watch?v=T9uZJFO54iM).
   Author's own walkthrough of pandoc's LaTeX back-end including
   `\begin{figure}` float placement, custom templates, and Lua filters.

3. **Tectonic Typesetting — Book / Introduction**
   [tectonic-typesetting.github.io](https://tectonic-typesetting.github.io/book/latest/introduction/index.html).
   Canonical documentation: XeTeX-powered, self-contained, targets
   byte-for-byte reproducible builds; embeddable as a Rust library —
   directly matching the repo's `trios-phd` integration.

4. **Tectonic GitHub Discussions — Fonts and Reproducibility #1228**
   [github.com/tectonic-typesetting/tectonic/discussions/1228](https://github.com/tectonic-typesetting/tectonic/discussions/1228).
   Documents the `CreationDate` workaround, `\let\pdfcreationdate=\creationdate`,
   and `-Z shell-escape` for reproducible builds. Directly relevant to the
   repo's byte-for-byte build requirement.

5. **Quarto documentation — Figures**
   [quarto.org/docs/authoring/figures.html](https://quarto.org/docs/authoring/figures.html).
   Comprehensive coverage of `fig-pos`, `fig-cap-location`, `fig-align`,
   subfigure layouts, and the `fig-pos: 'H'` forced placement for code
   output. Primary reference for the `IMAGE_PLACEMENT.md` rules.

6. **Mittelbach, F. (2018) — "Managing forlorn orphans and widows"**
   [TUGboat Vol. 39 No. 3](https://www.latex-project.org/publications/2018-FMi-TUB-tb123mitt-widows.pdf).
   LaTeX Project lead's definitive treatment of widow/orphan penalties and
   the `\looseness`, `\enlargethispage`, and `widows-and-orphans` package
   approaches. Grounds the repo's soft keep-together recommendation over
   hard `\clearpage` before sections.

7. **TeX FAQ — "Controlling widows and orphans"**
   [texfaq.org/FAQ-widows](https://texfaq.org/FAQ-widows).
   Community reference: `\widowpenalty`, `\clubpenalty`, finite vs infinite
   penalty settings; establishes why a soft approach (high penalty, not
   infinite) is preferable for multi-image chapter openers.

8. **LaTeX Project / Overleaf (2025) — "Creating accessible PDFs in LaTeX"**
   [docs.overleaf.com](https://docs.overleaf.com/writing-and-editing/creating-accessible-pdfs).
   TeX Live 2025 / LuaLaTeX tagged PDF workflow for PDF/UA-2 compliance;
   covers `\DocumentMetadata`, image alt text in `\includegraphics`, and
   `[H]` float placement for correct reading order.

9. **eSAIL TAMU (2025) — "Creating Accessible LaTeX PDFs: PDF/UA-2
   Compliance"**
   [esail.tamu.edu](https://esail.tamu.edu/faculty-tutorials/accessible-latex-pdf-ua-2-overleaf-2025/).
   Step-by-step guide: `\tagstructbegin`/`\tagstructend` wrappers for
   floating elements, `alt={}` in `\includegraphics`, `VeraPDF` for
   validation. Reference implementation for the repo's PDF/UA compliance
   path.

10. **Maedje, L. (2024) — "TeX and Typst: Layout Models"**
    [laurmaedje.github.io](https://laurmaedje.github.io/posts/layout-models/).
    Typst's creator compares its layout algorithm with TeX's; clarifies why
    TeX floats are algorithmically complex and what tectonic inherits from
    XeTeX's layout model.

### Synthesis

The scholarly PDF pipeline literature reinforces every element of the repo's
pipeline choice and its `IMAGE_PLACEMENT.md` / `TRIOS_PHD_NO_IMAGE_TRAIN`
rules with formal backing:

**Reproducibility.** Tectonic's core design goal is [byte-for-byte
reproducible builds](https://tectonic-typesetting.github.io/book/latest/introduction/index.html).
The `CreationDate` discussion (#1228) identifies one remaining non-determinism
and documents the workaround. Any CI pipeline that does not apply this
workaround is not reproducible despite using tectonic.

**Float placement.** LaTeX's float algorithm places figures in a specifier
priority order: `h` (here), `t` (top), `b` (bottom), `p` (float page). The
repo's "soft keep-together" rule — heading + hero image + first paragraph as
a unit — is technically implemented via `\begin{minipage}` or a
`{figure}[H]` with `[H]` from the `float` package. Mittelbach (2018) and the
TeX FAQ are the normative references for why infinite penalties (`\clearpage`
before every section) produce worse output (short pages, excessive whitespace)
than finite high penalties. The `TRIOS_PHD_NO_IMAGE_TRAIN` rule is exactly
this principle: do not hard-break before every image; instead keep heading,
image, and first paragraph together via a soft grouping.

**PDF/UA accessibility.** The Overleaf and eSAIL TAMU guides provide an
actionable path to PDF/UA-2 compliance: `\DocumentMetadata{tagging=on,
pdfstandard=ua-2}` + alt text on every `\includegraphics` + `[H]` float
specifiers for correct tag-tree reading order. The IMAGE_MANIFEST_SCHEMA
already captures alt text; the pipeline Lua filter should propagate it into
the generated `\includegraphics[alt={...}]` call.

**Semantic anchoring.** Quarto's `fig-pos` and caption-location system
confirms that the pandoc intermediate representation supports semantic
anchoring at the source level. The correct implementation is to set `fig-pos`
via a YAML front-matter key (not hard-coded LaTeX), making it overridable
per-chapter without touching the Lua filter.

### Recommendations

1. **Add to `IMAGE_PLACEMENT.md`**: cite Mittelbach (2018) and the TeX FAQ
   as normative references for the soft keep-together rule. Specify the
   implementation: `\begin{figure}[ht]` (not `[H]`) for hero images in the
   main text, with `\widowpenalty=9999` and `\clubpenalty=9999` in the
   preamble, combined with a `\needspace{6\baselineskip}` guard before each
   chapter opener to prevent a section heading from landing alone at the
   bottom of a page.

2. **Add to `02-pdf-style.md`**: a `CreationDate` reproducibility clause:
   the tectonic call in `pipeline.rs` MUST include the
   `\let\pdfcreationdate=\creationdate` workaround (or equivalent tectonic
   flag) so that two builds of the same SSOT content produce byte-identical
   PDFs. Failure to do so silently breaks content-hash validation.

3. **Add to `IMAGE_MANIFEST_SCHEMA.md`**: make `alt_text` a **required**
   (non-nullable) field. The Lua filter that generates `\includegraphics`
   calls must pass `alt_text` as the `alt=` keyword argument.
   Missing alt text must be a build-blocking QA error, not a warning.

4. **Add to `PDF_QA_CHECKLIST.md`**: a PDF/UA-2 validation step using
   `VeraPDF` (free, command-line): `verapdf --flavour ua2 output.pdf`.
   This is the only currently recommended tool for MathML tag validation
   per the eSAIL TAMU (2025) guide. Add the VeraPDF pass/fail output to
   the build artefact log.

5. **Add to `00-canonical-pipeline.md`**: a note that `fig-pos` for
   chapter hero images should be set to `'ht'` via the pandoc YAML
   front-matter key `fig-pos`, not via hard-coded LaTeX in the template.
   This allows per-chapter overrides without Lua filter changes and aligns
   with [Quarto's documented approach](https://quarto.org/docs/authoring/figures.html).

6. **Amend `02-pdf-style.md`**: document that tectonic uses the XeTeX
   engine and therefore requires OpenType fonts (not Type 1 / TFM) for
   correct Unicode rendering and PDF/UA compliance. Font choices must be
   declared as OTF/TTF in the LaTeX preamble, not as legacy LaTeX font
   packages.

---

