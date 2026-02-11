local parse_subgroups = {}

---@alias terminal-diagnostics.SubGroupResult { start_col: integer, end_col: integer }

---@class terminal-diagnostics.SubgroupParseResult
---@field path     terminal-diagnostics.SubGroupResult?
---@field lnum     terminal-diagnostics.SubGroupResult?
---@field col      terminal-diagnostics.SubGroupResult?
---@field severity terminal-diagnostics.SubGroupResult?
---@field message  terminal-diagnostics.SubGroupResult?
---@field code     terminal-diagnostics.SubGroupResult?

-- TODO: Define and expose somewhere
local subgroups = { "path", "lnum", "col", "severity", "code", "message" }

--- Parse the subgroups in a pattern and figure out their locations in the
--- matched string
---@param match_string string
---@param spec         terminal-diagnostics.MatchSpec
---@return terminal-diagnostics.SubgroupParseResult
function parse_subgroups.parse(match_string, spec)
    -- NOTE: This is a horrible solution but there is currently no builtin solution
    -- TODO: Does not work for multiline patterns
    local idx = 1
    local submatches = {}
    local pattern = spec.regex

    repeat
        -- Find the next unescaped regex group
        local _, start_col, end_col = unpack(
            vim.fn.matchstrpos(pattern, [[\v(\\|\%)@<!\(.{-}(\\|\%)@<!\)]], idx, 1)
        )

        if start_col == -1 then
            break
        end

        -- Reconstruct the pattern with match markers around the group that we found
        local subpattern = pattern:sub(1, start_col)
            .. "\\zs"
            .. pattern:sub(start_col + 1, end_col)
            .. "\\ze"
            .. pattern:sub(end_col + 1)

        local _, sub_start_col, sub_end_col =
            unpack(vim.fn.matchstrpos(match_string, subpattern))

        table.insert(
            submatches,
            { start_col = sub_start_col + 1, end_col = sub_end_col }
        )

        idx = end_col + 1
    until idx > #pattern

    ---@type terminal-diagnostics.SubgroupParseResult
    local results = {}

    for _, name in ipairs(subgroups) do
        local group_idx = spec[name]
        local submatch = submatches[group_idx]

        if group_idx and submatch then
            results[name] = submatches[group_idx]
        end
    end

    return results
end

return parse_subgroups
