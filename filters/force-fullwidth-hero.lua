-- Hero images: full-width raw LaTeX, no figure/caption to avoid
-- duplicate-label clashes with pandoc 3.x's Figure wrapping.

function Figure(elem)
  if #elem.content >= 1 and elem.content[1].t == "Plain" then
    local plain = elem.content[1]
    if #plain.content == 1 and plain.content[1].t == "Image" then
      local img = plain.content[1]
      if img.classes:includes("secondary") then
        -- Secondary/context images stay anchored in the surrounding prose.
        -- Use a soft Needspace request so LaTeX may move the block when it
        -- will not fit, without forcing image-train pages via \clearpage.
        return pandoc.RawBlock('latex',
          '\\par\\Needspace{0.36\\textheight}\\vspace{0.35em}'
          .. '\\noindent\\begin{center}\\includegraphics[width=\\textwidth,height=0.32\\textheight,keepaspectratio]{'
          .. img.src .. '}\\end{center}'
          .. '\\vspace{0.35em}\\par')
      end
      if img.classes:includes("hero") then
        return pandoc.RawBlock('latex',
          '\\par\\Needspace{0.48\\textheight}\\vspace{0.5em}\\noindent\\includegraphics[width=\\textwidth,height=0.42\\textheight,keepaspectratio]{'
          .. img.src .. '}\\vspace{0.5em}')
      end
    end
  end
  return elem
end

-- Wide tables (>=6 columns): convert longtable → tabular wrapped in
-- \resizebox{\linewidth}{!}{...} so math-heavy cells can never overflow
-- into the next column. Only safe for tables that fit on one page; the
-- compendium's catalog tables all do.
function Table(elem)
  if elem.colspecs and #elem.colspecs >= 6 then
    local n = #elem.colspecs
    local doc = pandoc.Pandoc({elem})
    local latex = pandoc.write(doc, "latex")

    -- Replace pandoc's percent-width p{} colspec with simple `l` columns
    -- separated by explicit @{\hskip 8pt} gaps. The tabular then has its
    -- natural width (typically > \linewidth), \resizebox scales it down,
    -- and the explicit gaps survive the scaling — no cell can overflow
    -- into its neighbour, even with long monospace identifiers.
    local sep = "@{\\hskip 8pt}"
    local newcols = "@{}" .. string.rep("l" .. sep, n - 1) .. "l@{}"
    -- Either longtable or tabular colspec block — replace whichever is there.
    latex = latex:gsub("\\begin{longtable}%[?%w-%]?%b{}", "\\begin{tabular}{" .. newcols .. "}")
    latex = latex:gsub("\\begin{tabular}%[?%w-%]?%b{}", "\\begin{tabular}{" .. newcols .. "}")

    -- Strip minipage wrappers in header cells (they were needed for p{},
    -- but with l columns they would force per-cell width = \linewidth).
    latex = latex:gsub("\\begin{minipage}%[?%w-%]?%b{}\\raggedright%s*", "")
    latex = latex:gsub("\\begin{minipage}%[?%w-%]?%b{}%s*", "")
    latex = latex:gsub("\\end{minipage}", "")

    -- Drop longtable-only commands so the body works inside tabular.
    latex = latex:gsub("\\end{longtable}", "\\end{tabular}")
    latex = latex:gsub("\\endfirsthead", "")
    latex = latex:gsub("\\endhead", "")
    latex = latex:gsub("\\endfoot", "")
    latex = latex:gsub("\\endlastfoot", "")
    latex = latex:gsub("\\caption%b{}\\\\", "")
    latex = latex:gsub("\\tabularnewline", "\\\\")

    return pandoc.RawBlock("latex",
      "\\begin{center}\\noindent\\resizebox{\\linewidth}{!}{%\n"
      .. latex .. "}\\end{center}")
  end
  return elem
end
