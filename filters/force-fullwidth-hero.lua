-- Hero images: full-width raw LaTeX, no figure/caption to avoid
-- duplicate-label clashes with pandoc 3.x's Figure wrapping.
--
-- Also handles Unicode super/subscript fallback: latinmodern-math
-- lacks glyphs for U+00B2 ², U+00B3 ³, U+207B ⁻, U+00B9 ¹, U+207A ⁺,
-- U+2070-U+2079 superscript digits. Pandoc emits them as plain Str,
-- which prints flat (S3 AI, φ2, α−1). We rewrite to \textsuperscript{...}
-- raw LaTeX so they render properly with latinmodern roman.

-- Map of Unicode super/subscript codepoint → ASCII char
local SUP_MAP = {
  ['\u{2070}']='0', ['\u{00B9}']='1', ['\u{00B2}']='2', ['\u{00B3}']='3',
  ['\u{2074}']='4', ['\u{2075}']='5', ['\u{2076}']='6', ['\u{2077}']='7',
  ['\u{2078}']='8', ['\u{2079}']='9',
  ['\u{207A}']='+', ['\u{207B}']='-', ['\u{207C}']='=', ['\u{207D}']='(',
  ['\u{207E}']=')', ['\u{207F}']='n',
  ['\u{2071}']='i',
}
local SUB_MAP = {
  ['\u{2080}']='0', ['\u{2081}']='1', ['\u{2082}']='2', ['\u{2083}']='3',
  ['\u{2084}']='4', ['\u{2085}']='5', ['\u{2086}']='6', ['\u{2087}']='7',
  ['\u{2088}']='8', ['\u{2089}']='9',
  ['\u{208A}']='+', ['\u{208B}']='-', ['\u{208C}']='=', ['\u{208D}']='(',
  ['\u{208E}']=')',
}

-- Recognize a run of consecutive super/sub codepoints and emit one
-- LaTeX command per run. Iterates char-by-char; pandoc Strs are utf8.
local function rewrite_super_sub(s)
  -- Quick guard: if the string contains no super/sub codepoint, skip.
  if not s:find('[\194\226]') then return s end  -- prefix bytes of UTF-8
  local out, i, n = {}, 1, #s
  while i <= n do
    local b = s:byte(i)
    local clen = 1
    if b >= 0xF0 then clen = 4
    elseif b >= 0xE0 then clen = 3
    elseif b >= 0xC0 then clen = 2 end
    local cp = s:sub(i, i + clen - 1)
    -- Try to extend run: collect successive sup chars
    local run_kind, run_chars = nil, {}
    while true do
      local nb = s:byte(i)
      if not nb then break end
      local nlen = 1
      if nb >= 0xF0 then nlen = 4
      elseif nb >= 0xE0 then nlen = 3
      elseif nb >= 0xC0 then nlen = 2 end
      local ncp = s:sub(i, i + nlen - 1)
      if SUP_MAP[ncp] and (run_kind == nil or run_kind == 'sup') then
        run_kind = 'sup'
        run_chars[#run_chars + 1] = SUP_MAP[ncp]
        i = i + nlen
      elseif SUB_MAP[ncp] and (run_kind == nil or run_kind == 'sub') then
        run_kind = 'sub'
        run_chars[#run_chars + 1] = SUB_MAP[ncp]
        i = i + nlen
      else
        break
      end
    end
    if run_kind then
      local payload = table.concat(run_chars)
      if run_kind == 'sup' then
        out[#out + 1] = '\\textsuperscript{' .. payload .. '}'
      else
        out[#out + 1] = '\\textsubscript{' .. payload .. '}'
      end
    else
      -- Non-sup/sub char: emit verbatim
      out[#out + 1] = cp
      i = i + clen
    end
  end
  return table.concat(out)
end

-- Caret-pattern rewriter (B5 v8):
-- Pandoc parses literal `F^*`, `R^+`, `10^-3`, `Z^d` outside math as a flat
-- ASCII `^` followed by characters. They render as a Computer-Modern caret
-- glyph and the next chars sit on the baseline, producing illegible math.
-- We rewrite specific tight patterns to \textsuperscript{...}:
--   * single letter + ^ + (one * or +)            → F^*, R^+, Z^*
--   * single letter + ^ + (one alphanum)          → Z^d, M^N (rare)
--   * digit(s) + ^ + (optional - and 1-3 digits)  → 10^-3, 10^9
-- Only operates on Str tokens (i.e. inline text), so display math and code
-- spans are untouched. To stay conservative we DO NOT rewrite trailing
-- alphanumeric runs longer than 3 chars (avoids splitting filenames or
-- references like `commit^abc1234`).
local function rewrite_carets(s)
  if not s:find('%^') then return s end
  -- Pattern A: <letter>^<*|+>  (e.g. F^*, R^+)
  s = s:gsub('(%f[%w_])(%a)%^([%*%+])', function(boundary, lhs, op)
    return boundary .. lhs .. '\\textsuperscript{' .. op .. '}'
  end)
  -- Pattern B: <digit-run>^-?<digit-run>  (e.g. 10^-3, 10^9, 10^23)
  s = s:gsub('(%d+)%^(%-?%d+)', function(base, exp)
    return base .. '\\textsuperscript{' .. exp .. '}'
  end)
  -- Pattern C: <letter>^<single letter or digit>   (e.g. Z^d, M^N)
  -- Conservative: only one trailing alphanumeric to avoid breaking refs.
  s = s:gsub('(%f[%w_])(%a)%^(%w)(%f[%W_])', function(b, lhs, ch, e)
    return b .. lhs .. '\\textsuperscript{' .. ch .. '}' .. e
  end)
  return s
end

function Str(elem)
  -- First handle caret patterns (B5). If rewritten, emit as RawInline since
  -- it now contains literal LaTeX. We then still feed through the super/sub
  -- pass below.
  local caret_text = rewrite_carets(elem.text)
  if caret_text ~= elem.text then
    -- Inject as RawInline; the super/sub fallback only matters for true
    -- Unicode super/sub codepoints in source, which won't appear inside
    -- a string we just expanded with LaTeX commands.
    return pandoc.RawInline('latex', caret_text)
  end
  local rewritten = rewrite_super_sub(elem.text)
  if rewritten == elem.text then return nil end  -- no change
  -- If we introduced LaTeX, return a RawInline so pandoc preserves it.
  -- Mix of raw and text: split into Inlines list.
  -- Simplest: if the entire string was super/sub only, emit one RawInline;
  -- otherwise emit a list of Str + RawInline alternating.
  local parts = {}
  -- Re-walk, building an Inlines list (text vs raw)
  local i, n = 1, #elem.text
  local s = elem.text
  local buf = {}
  while i <= n do
    local b = s:byte(i)
    local clen = 1
    if b >= 0xF0 then clen = 4
    elseif b >= 0xE0 then clen = 3
    elseif b >= 0xC0 then clen = 2 end
    local cp = s:sub(i, i + clen - 1)
    if SUP_MAP[cp] or SUB_MAP[cp] then
      -- flush buf as Str
      if #buf > 0 then
        parts[#parts + 1] = pandoc.Str(table.concat(buf))
        buf = {}
      end
      local kind = SUP_MAP[cp] and 'sup' or 'sub'
      local map  = SUP_MAP[cp] and SUP_MAP or SUB_MAP
      local chars = { map[cp] }
      i = i + clen
      while i <= n do
        local nb = s:byte(i)
        local nlen = 1
        if nb >= 0xF0 then nlen = 4
        elseif nb >= 0xE0 then nlen = 3
        elseif nb >= 0xC0 then nlen = 2 end
        local ncp = s:sub(i, i + nlen - 1)
        if (kind == 'sup' and SUP_MAP[ncp]) or (kind == 'sub' and SUB_MAP[ncp]) then
          chars[#chars + 1] = map[ncp]
          i = i + nlen
        else
          break
        end
      end
      local payload = table.concat(chars)
      local cmd = (kind == 'sup') and '\\textsuperscript{' or '\\textsubscript{'
      parts[#parts + 1] = pandoc.RawInline('latex', cmd .. payload .. '}')
    else
      buf[#buf + 1] = cp
      i = i + clen
    end
  end
  if #buf > 0 then parts[#parts + 1] = pandoc.Str(table.concat(buf)) end
  return parts
end

function Figure(elem)
  if #elem.content >= 1 and elem.content[1].t == "Plain" then
    local plain = elem.content[1]
    if #plain.content == 1 and plain.content[1].t == "Image" then
      local img = plain.content[1]
      if img.classes:includes("secondary") then
        -- Secondary/context images: canonical-tail Pellis triptychs
        -- need to be **readable** — earlier 0.20\textheight (~5cm)
        -- shrunk the TARGET/CLAIM/PHI ALGEBRA labels to illegible.
        -- Match hero-class footprint (0.40\textheight ≈ 10cm) so the
        -- triptych panels read at arm's length; LaTeX will move the
        -- image to its own page if the chapter tail can't accommodate.
        local cap_txt = ''
        if elem.caption and elem.caption.long then
          cap_txt = pandoc.utils.stringify(elem.caption.long)
        end
        local cap_line = ''
        if cap_txt ~= '' then
          cap_txt = cap_txt:gsub('([%%&#_])', '\\%1')
          -- Plain caption text — no \captionof. Earlier attempts:
          -- (a) capt-of + \captionof{figure} → 18 "Object @figure.N.N
          --     already defined" anchor warnings (counter collided across
          --     chapters).
          -- (b) caption package → conflict with pandoc's \LTcaptype{none}
          --     longtable wrappers → build error.
          -- Plain paragraph: no counter increment, no anchor, no float —
          -- matches the canonical-tail's caption style anyway.
          cap_line = '{\\footnotesize\\itshape ' .. cap_txt .. '}'
        end
        return pandoc.RawBlock('latex',
          '\\par\\Needspace{0.45\\textheight}\\vspace{0.5em}'
          .. '\\noindent\\begin{center}\\includegraphics[width=\\textwidth,height=0.40\\textheight,keepaspectratio]{'
          .. img.src .. '}\\\\[3pt]' .. cap_line
          .. '\\end{center}\\vspace{0.5em}\\par')
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
