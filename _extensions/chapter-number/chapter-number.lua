-- chapter-number.lua
-- Automatically sets the chapter counter based on 'chapter-number' metadata
-- Usage: Add 'chapter-number: 3' to your YAML front matter

function Meta(meta)
  if meta['chapter-number'] then
    local num = tonumber(pandoc.utils.stringify(meta['chapter-number']))
    if num and FORMAT:match('latex') then
      -- Set chapter counter to N-1 so the next \chapter command produces N
      local latex_cmd = string.format("\\setcounter{chapter}{%d}", num - 1)
      
      -- Insert at the beginning of the document
      return meta, {
        pandoc.RawBlock('latex', latex_cmd)
      }
    end
  end
  return meta
end

function Pandoc(doc)
  local meta = doc.meta
  if meta['chapter-number'] then
    local num = tonumber(pandoc.utils.stringify(meta['chapter-number']))
    if num and FORMAT:match('latex') then
      local latex_cmd = string.format("\\setcounter{chapter}{%d}", num - 1)
      table.insert(doc.blocks, 1, pandoc.RawBlock('latex', latex_cmd))
    end
  end
  return doc
end
