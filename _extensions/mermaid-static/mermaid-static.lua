-- mermaid-static.lua
-- In CI (GITHUB_ACTIONS=true), replace mermaid code blocks with pre-compiled SVG images
-- Locally, let mermaid render normally

local in_ci = os.getenv("GITHUB_ACTIONS") == "true" or os.getenv("CI") == "true"

function CodeBlock(el)
  -- Only process mermaid blocks
  if not el.classes:includes("mermaid") then
    return nil
  end
  
  -- If not in CI, let Quarto handle mermaid normally
  if not in_ci then
    return nil
  end
  
  -- In CI: replace with pre-compiled SVG
  -- Generate a hash of the mermaid content to find the corresponding SVG
  local content = el.text
  local hash = pandoc.sha1(content):sub(1, 8)
  
  -- Look for SVG in _mermaid-cache directory
  local svg_path = "_mermaid-cache/" .. hash .. ".svg"
  
  -- Check if the SVG exists
  local f = io.open(svg_path, "r")
  if f then
    f:close()
    -- Return an image element pointing to the SVG
    local img = pandoc.Image({}, svg_path, "", {width = "100%"})
    return pandoc.Para({img})
  else
    -- SVG not found - return a warning message
    quarto.log.warning("Mermaid SVG not found: " .. svg_path .. " - run 'make mermaid' locally")
    return pandoc.Para({pandoc.Strong({pandoc.Str("[Mermaid diagram - run 'make mermaid' to compile]")})})
  end
end
