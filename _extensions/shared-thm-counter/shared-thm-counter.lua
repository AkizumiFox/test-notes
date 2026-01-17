-- shared-thm-counter.lua
-- Debug version

local shared_counter = 0
local definition_counter = 0
local current_chapter = 0

local shared_types = {
  lemma = true,
  corollary = true,
  proposition = true
}

local no_counter_types = {
  conjecture = true,
  example = true,
  exercise = true,
  solution = true,
  remark = true,
  algorithm = true
}

local function get_env_type(classes)
  local has_theorem = false
  
  for _, class in ipairs(classes) do
    if class == "theorem" then
      has_theorem = true
    elseif class == "definition" then
      return "definition"
    elseif shared_types[class] then
      return class
    elseif no_counter_types[class] then
      return class
    end
  end
  
  if has_theorem then
    return "theorem_shared"
  end
  
  return nil
end

function Header(el)
  if el.level == 1 then
    current_chapter = current_chapter + 1
    shared_counter = 0
    definition_counter = 0
    io.stderr:write("[shared-thm-counter] Chapter " .. current_chapter .. "\n")
  end
  return el
end

function Div(el)
  local env_type = get_env_type(el.classes)
  
  if not env_type then
    return el
  end
  
  io.stderr:write("[shared-thm-counter] Found " .. env_type .. "\n")
  
  local new_num = nil
  
  if env_type == "definition" then
    definition_counter = definition_counter + 1
    new_num = string.format("%d.%d", current_chapter, definition_counter)
  elseif env_type == "theorem_shared" or shared_types[env_type] then
    shared_counter = shared_counter + 1
    new_num = string.format("%d.%d", current_chapter, shared_counter)
  elseif no_counter_types[env_type] then
    new_num = ""
  end
  
  io.stderr:write("[shared-thm-counter] New num: " .. (new_num or "nil") .. "\n")
  
  if new_num == nil then
    return el
  end
  
  -- Walk and modify
  el = el:walk({
    Span = function(span)
      local is_title = false
      for _, class in ipairs(span.classes) do
        if class == "theorem-title" then
          is_title = true
          break
        end
      end
      
      if not is_title then
        return span
      end
      
      io.stderr:write("[shared-thm-counter] Found theorem-title span\n")
      
      local new_content = pandoc.List()
      for _, child in ipairs(span.content) do
        if child.t == "Strong" then
          local parts = {}
          for _, c in ipairs(child.content) do
            if c.t == "Str" then
              table.insert(parts, c.text)
            elseif c.t == "Space" then
              table.insert(parts, " ")
            end
          end
          local full_text = table.concat(parts)
          io.stderr:write("[shared-thm-counter] Original text: " .. full_text .. "\n")
          
          local type_name, rest = full_text:match("^(%a+)%s+%d+%.%d+(.*)$")
          
          if type_name then
            local new_text
            if new_num == "" then
              if rest and rest:match("^%s*%(") then
                new_text = type_name .. rest:gsub("^%s*", " ")
              else
                new_text = type_name .. (rest or "")
              end
            else
              new_text = type_name .. " " .. new_num .. (rest or "")
            end
            io.stderr:write("[shared-thm-counter] New text: " .. new_text .. "\n")
            new_content:insert(pandoc.Strong(pandoc.Str(new_text)))
          else
            new_content:insert(child)
          end
        else
          new_content:insert(child)
        end
      end
      span.content = new_content
      return span
    end
  })
  
  return el
end

return {
  {Header = Header},
  {Div = Div}
}
