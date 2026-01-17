-- mermaid-static.lua
-- Use ```{.mermaid-src #id} blocks that get transformed to:
-- - Real mermaid blocks (locally) 
-- - SVG images (in CI)
-- This avoids Quarto initializing Chromium when it sees {mermaid} blocks

local in_ci = os.getenv("GITHUB_ACTIONS") == "true" or os.getenv("CI") == "true"

-- Get the project root directory
local function get_project_root()
  -- Try to find _quarto.yml to determine project root
  local path = ""
  for i = 1, 5 do
    local f = io.open(path .. "_quarto.yml", "r")
    if f then
      f:close()
      return path
    end
    path = "../" .. path
  end
  return ""
end

function CodeBlock(el)
  -- Only process mermaid-src blocks (our custom class)
  if not el.classes:includes("mermaid-src") then
    return nil
  end
  
  local content = el.text
  
  if in_ci then
    -- In CI: replace with pre-compiled SVG
    -- Use the block's ID as the filename, or fall back to content hash
    local svg_name = el.identifier
    if svg_name == "" then
      svg_name = pandoc.sha1(content):sub(1, 8)
    end
    
    local project_root = get_project_root()
    local svg_path = project_root .. "_mermaid-cache/" .. svg_name .. ".svg"
    
    -- Check if the SVG exists
    local f = io.open(svg_path, "r")
    if f then
      f:close()
      -- Return an image element pointing to the SVG
      local img = pandoc.Image({}, svg_path, "", {width = "100%"})
      return pandoc.Para({img})
    else
      -- SVG not found - return a warning
      quarto.log.warning("Mermaid SVG not found: " .. svg_path .. " - run 'make mermaid' locally")
      return pandoc.Para({pandoc.Strong({pandoc.Str("[Mermaid diagram '" .. svg_name .. "' - run 'make mermaid' to compile]")})})
    end
  else
    -- Locally: convert to real mermaid block for Quarto to render
    el.classes = {"mermaid"}
    return el
  end
end
