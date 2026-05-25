-- Hero images: full-width raw LaTeX, no figure/caption to avoid
-- duplicate-label clashes with pandoc 3.x's Figure wrapping.

function Figure(elem)
  if #elem.content >= 1 and elem.content[1].t == "Plain" then
    local plain = elem.content[1]
    if #plain.content == 1 and plain.content[1].t == "Image" then
      local img = plain.content[1]
      if img.classes:includes("secondary") then
        -- Secondary/context images: tighter footprint so they always fit
        -- with text on the same page (no lone-banner pages). 0.22 textheight
        -- (~5cm) keeps the banner visible without dominating; small
        -- Needspace lets LaTeX move it if even that won't fit.
        return pandoc.RawBlock('latex',
          '\\par\\Needspace{0.22\\textheight}\\vspace{0.3em}'
          .. '\\noindent\\begin{center}\\includegraphics[width=0.92\\textwidth,height=0.20\\textheight,keepaspectratio]{'
          .. img.src .. '}\\end{center}'
          .. '\\vspace{0.3em}\\par')
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

-- Aggressive keep-together for "References" subsections.
-- Empty / single-bullet "ghost reference" pages were the residual cause of
-- low-context pages in QA. We combine three soft mechanisms before the
-- heading so LaTeX has multiple chances to keep the heading + its short
-- itemize on the same page as the chapter's tail content:
--   * \enlargethispage  — grant ~2 baselineskips extra room on current page
--   * \nopagebreak[3]   — strong discouragement of a break right after tail
--   * \Needspace{0.6h}   — increased threshold so short reference blocks
--                          are forced to stay with preceding tail content
function Plain(elem)
  local text = pandoc.utils.stringify(elem):lower()
  if text:find("data availability") then
    return {
      pandoc.RawBlock('latex', '\\nopagebreak[4]'),
      elem,
    }
  end
  return elem
end

function Para(elem)
  local text = pandoc.utils.stringify(elem):lower()
  if text:find("for paper 3") or text:find("data availability") then
    return {
      pandoc.RawBlock('latex', '\\nopagebreak[4]'),
      elem,
    }
  end
  return elem
end

function Header(elem)
  local text = pandoc.utils.stringify(elem):lower()
  if text:find("references")
     or text:find("author contributions")
     or text:find("data availability") then
    return {
      pandoc.RawBlock('latex',
        '\\enlargethispage{2\\baselineskip}\\nopagebreak[3]\\Needspace{0.6\\textheight}'),
      elem,
    }
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
    latex = latex:gsub("\\caption%b{}\\tabularnewline", "")
    latex = latex:gsub("\\tabularnewline", "\\\\")

    return pandoc.RawBlock("latex",
      "\\begin{center}\\noindent\\resizebox{\\linewidth}{!}{%\n"
      .. latex .. "}\\end{center}")
  end
  return elem
end
