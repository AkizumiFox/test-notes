-- mermaid-static.lua
-- Use ```{.mermaid-src #id} blocks that get transformed to:
-- - Real mermaid blocks (locally) 
-- - Pre-compiled images (in CI): SVG for HTML, PNG for PDF
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
    -- In CI: replace with pre-compiled image
    -- Use the block's ID as the filename, or fall back to content hash
    local img_name = el.identifier
    if img_name == "" then
      img_name = pandoc.sha1(content):sub(1, 8)
    end
    
    local project_root = get_project_root()
    
    -- Try PNG first (works for both HTML and PDF), then SVG
    local png_path = project_root .. "_mermaid-cache/" .. img_name .. ".png"
    local svg_path = project_root .. "_mermaid-cache/" .. img_name .. ".svg"
    
    local img_path = nil
    local f = io.open(png_path, "r")
    if f then
      f:close()
      img_path = png_path
    else
      f = io.open(svg_path, "r")
      if f then
        f:close()
        img_path = svg_path
      end
    end
    
    if img_path then
      -- Return an image element
      local img = pandoc.Image({}, img_path, "", {width = "100%"})
      return pandoc.Para({img})
    else
      -- Image not found - return a warning
      quarto.log.warning("Mermaid image not found: " .. png_path .. " or " .. svg_path .. " - run 'make mermaid' locally")
      return pandoc.Para({pandoc.Strong({pandoc.Str("[Mermaid diagram '" .. img_name .. "' - run 'make mermaid' to compile]")})})
    end
  else
    -- Locally: convert to real mermaid block for Quarto to render
    el.classes = {"mermaid"}
    return el
  end
end
