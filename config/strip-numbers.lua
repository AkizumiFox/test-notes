-- strip-numbers.lua
-- LuaLaTeX callback to strip numbers from theorem-like environment titles
-- Usage: \directlua{require("strip-numbers")} in LaTeX preamble

-- Environments to strip numbers from (capitalized as they appear in output)
local unnumbered = {
    ["Conjecture"] = true,
    ["Example"] = true,
    ["Exercise"] = true,
    ["Solution"] = true,
    ["Remark"] = true,
    ["Algorithm"] = true,
}

-- Process node callback to modify theorem titles
local function process_chars(head)
    -- This is complex because we need to modify glyph nodes
    -- Skip for now - this approach is too low-level
    return head
end

-- Alternative: use process_input_buffer to modify TeX input
local function strip_theorem_numbers(line)
    -- Pattern: EnvName X.Y (Title) or EnvName X.Y.
    for env, _ in pairs(unnumbered) do
        -- With parenthetical title in textbf
        line = line:gsub(
            "\\textbf{" .. env .. " (%d+%.%d+) %((.-)%)}",
            "\\textbf{" .. env .. " (%2)}"
        )
        -- Without title in textbf
        line = line:gsub(
            "\\textbf{" .. env .. " %d+%.%d+%.}",
            "\\textbf{" .. env .. ".}"
        )
        line = line:gsub(
            "\\textbf{" .. env .. " %d+%.%d+}",
            "\\textbf{" .. env .. "}"
        )
        -- For emph style (e.g., remark without title): \emph{Remark 6.1}
        line = line:gsub(
            "\\emph{" .. env .. " %d+%.%d+}",
            "\\emph{" .. env .. "}"
        )
        -- For \\textit style
        line = line:gsub(
            "\\textit{" .. env .. " %d+%.%d+}",
            "\\textit{" .. env .. "}"
        )
        
        -- Fix spacing when counter is empty: "Remark ." -> "Remark."
        -- and "Remark . " -> "Remark. "
        line = line:gsub("\\emph{" .. env .. "} %.", "\\emph{" .. env .. "}.")
        line = line:gsub("\\emph{" .. env .. "}%s+%.", "\\emph{" .. env .. "}.")
        line = line:gsub("\\textit{" .. env .. "} %.", "\\textit{" .. env .. "}.")
        line = line:gsub("\\textit{" .. env .. "}%s+%.", "\\textit{" .. env .. "}.")
    end
    return line
end

-- Register the callback
luatexbase.add_to_callback("process_input_buffer", strip_theorem_numbers, "strip_theorem_numbers")

return {}
