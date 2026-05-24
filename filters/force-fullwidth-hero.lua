-- Force full-width hero images on chapter openers
-- Pandoc 3.x wraps standalone images in Figure elements.
-- We replace hero-class figures with raw LaTeX to avoid
-- automatic caption/label duplication.

function Figure(elem)
  -- elem.content[1] should be the Plain block containing the Image
  if #elem.content >= 1 and elem.content[1].t == "Plain" then
    local plain = elem.content[1]
    if #plain.content == 1 and plain.content[1].t == "Image" then
      local img = plain.content[1]
      if img.classes:includes("hero") then
        return pandoc.RawBlock('latex',
          '\\vspace{0.5em}\\noindent\\includegraphics[width=\\textwidth]{' .. img.src .. '}\\vspace{0.5em}')
      end
    end
  end
  return elem
end
