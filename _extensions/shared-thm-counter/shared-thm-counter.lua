-- shared-thm-counter.lua
-- Makes Theorem, Lemma, Corollary, and Proposition share a single counter
-- Removes counters from Conjecture, Example, Exercise, Solution

-- Track the shared counter per chapter.section
local shared_counter = {}
local current_chapter = 0
local current_section = 0

-- Environment types that share the counter
local shared_types = {
  theorem = true,
  lemma = true,
  corollary = true,
  proposition = true
}

-- Environment types that should have NO counter
local no_counter_types = {
  conjecture = true,
  example = true,
  exercise = true,
  solution = true
}

-- Function to get counter key based on chapter.section
local function get_counter_key()
  return string.format("%d.%d", current_chapter, current_section)
end

-- Function to increment and get the next number
local function get_next_number()
  local key = get_counter_key()
  if not shared_counter[key] then
    shared_counter[key] = 0
  end
  shared_counter[key] = shared_counter[key] + 1
  return shared_counter[key]
end

-- Track section numbers from headers
function Header(el)
  if el.level == 1 then
    current_chapter = current_chapter + 1
    current_section = 0
  elseif el.level == 2 then
    current_section = current_section + 1
  end
  return el
end

-- Process theorem divs
function Div(el)
  -- Check if this is a shared counter type
  local is_shared = false
  local is_no_counter = false
  local env_type = nil
  
  for _, class in ipairs(el.classes) do
    if shared_types[class] then
      is_shared = true
      env_type = class
      break
    elseif no_counter_types[class] then
      is_no_counter = true
      env_type = class
      break
    end
  end
  
  if is_shared then
    -- Get the next shared number
    local num = get_next_number()
    local full_num = string.format("%d.%d.%d", current_chapter, current_section, num)
    
    -- Find and update the theorem title span
    el = el:walk({
      Span = function(span)
        for _, class in ipairs(span.classes) do
          if class:match("%-title$") then
            -- Rebuild content with new number
            local new_content = {}
            local in_number = false
            local number_done = false
            
            for _, item in ipairs(span.content) do
              if item.t == "Str" then
                local text = item.text
                if not number_done and text:match("^%d") then
                  -- This is the number - replace it
                  table.insert(new_content, pandoc.Str(full_num))
                  number_done = true
                  in_number = true
                elseif in_number and text:match("^%.%d") then
                  -- Skip continuation of old number
                elseif in_number and not text:match("^[%.%d]") then
                  -- End of number
                  in_number = false
                  table.insert(new_content, item)
                elseif not in_number then
                  table.insert(new_content, item)
                end
              else
                if in_number then
                  in_number = false
                end
                table.insert(new_content, item)
              end
            end
            span.content = new_content
            return span
          end
        end
        return span
      end
    })
  elseif is_no_counter then
    -- Remove the number from title
    el = el:walk({
      Span = function(span)
        for _, class in ipairs(span.classes) do
          if class:match("%-title$") then
            local new_content = {}
            local skip_number = true
            
            for _, item in ipairs(span.content) do
              if item.t == "Str" then
                local text = item.text
                if skip_number and text:match("^%d") then
                  -- Skip the number
                elseif skip_number and text:match("^[%.%d]") then
                  -- Skip continuation of number
                else
                  skip_number = false
                  table.insert(new_content, item)
                end
              elseif item.t == "Space" and skip_number then
                -- Skip space after number
                skip_number = false
              else
                table.insert(new_content, item)
              end
            end
            span.content = new_content
            return span
          end
        end
        return span
      end
    })
  end
  
  return el
end

return {
  {Header = Header},
  {Div = Div}
}
