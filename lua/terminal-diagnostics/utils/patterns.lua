-- TODO: Rename to 'search'?
local patterns = {}

---@alias terminal-diagnostics.SubGroupResult { start_col: integer, end_col: integer }

---@class terminal-diagnostics.SubgroupParseResult
---@field path     terminal-diagnostics.SubGroupResult?
---@field lnum     terminal-diagnostics.SubGroupResult?
---@field col      terminal-diagnostics.SubGroupResult?
---@field severity terminal-diagnostics.SubGroupResult?
---@field message  terminal-diagnostics.SubGroupResult?
---@field code     terminal-diagnostics.SubGroupResult?

local function keep_cursor(func)
    local cursor = vim.api.nvim_win_get_cursor(0)

    func()

    vim.api.nvim_win_set_cursor(0, cursor)
end

---@param buffer       integer
---@param spec         terminal-diagnostics.MatchSpec
---@param first_match  terminal-diagnostics.Position
---@param second_match terminal-diagnostics.Position
---@return terminal-diagnostics.Match
local function create_match(buffer, spec, first_match, second_match)
    local text = {
        table.concat(
            vim.api.nvim_buf_get_text(
                buffer,
                first_match[1] - 1,
                first_match[2] - 1,
                second_match[1] - 1,
                second_match[2],
                {}
            ),
            "\n"
        ),
    }

    local submatches = vim.fn.matchstrlist(text, spec.pattern, { submatches = true })

    return {
        text = text,
        submatches = submatches[1] and submatches[1].submatches or {},
        from = {
            lnum = first_match[1],
            col = first_match[2],
        },
        to = {
            lnum = second_match[1],
            col = second_match[2],
        },
        spec = spec,
    }
end

---@param buffer integer
---@param spec   terminal-diagnostics.MatchSpec
---@param count  integer?
---@return terminal-diagnostics.Match?
function patterns.find(buffer, spec, count)
    local match
    local _count = count or 1
    local extra_flags = _count > 0 and "W" or "bW" -- TODO: Make wrap configurable
    local pattern = spec.pattern

    -- TODO: Does this find something on the same line as a valid pattern
    keep_cursor(function()
        local first_match = vim.fn.searchpos(pattern, extra_flags)

        if first_match[1] == 0 and first_match[2] == 0 then
            return
        end

        local second_match = vim.fn.searchpos(pattern, "ceW")

        if second_match[1] == 0 and second_match[2] == 0 then
            return
        end

        match = create_match(buffer, spec, first_match, second_match)
    end)

    return match
end

---@param buffer integer
---@param spec terminal-diagnostics.MatchSpec
---@return terminal-diagnostics.Match?
function patterns.find_at_cursor(buffer, spec)
    local match
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    col = col + 1
    local first_match = vim.fn.searchpos(spec.pattern, "cnbW")

    if first_match[1] == 0 then
        if not spec.multiline and first_match[1] ~= lnum then
            return
        end
    end

    local second_match = vim.fn.searchpos(spec.pattern, "cneW")

    if second_match[1] == 0 then
        if not spec.multiline and second_match[1] ~= lnum then
            return
        end
    end

    if lnum >= first_match[1] and lnum <= second_match[1] then
        if col >= first_match[2] and col <= second_match[2] then
            match = create_match(buffer, spec, first_match, second_match)
        end
    end

    return match
end

---@param lines string[]
---@param match_spec terminal-diagnostics._ResolvedMatchSpec
---@param start_lnum integer?
---@return integer
function patterns.find_in_lines(lines, match_spec, start_lnum)
    for lnum = start_lnum or 1, #lines do
        if patterns.find_at_line_fast(lines, match_spec, lnum) then
            return lnum
        end
    end

    return -1
end

local function merge_submatches(target, submatches)
    local end_idx

    -- Merge backwards because empty matches might occur between
    -- non-empty matches due to optional capture groups e.g.
    --
    -- { "a", "", "b", "c", "", "", "", "", "" }
    for idx = #submatches, 1, -1 do
        if submatches[idx] ~= "" then
            end_idx = idx
            break
        end
    end

    if not end_idx then
        return
    end

    for idx = 1, end_idx do
        table.insert(target, submatches[idx])
    end
end

---@param lines string[]
---@param match_spec terminal-diagnostics._ResolvedMatchSpec
---@param lnum integer
---@return terminal-diagnostics.Match?
function patterns.find_at_line(lines, match_spec, lnum)
    local text = {}
    local submatches = {}
    local from = { lnum = lnum, col = math.huge }
    local to = { lnum = -1, col = -1 }
    local match_count = 0

    lnum = lnum or 1

    for pidx, subpattern in ipairs(match_spec.subpatterns) do
        local offset = lnum + pidx - 1
        local line = lines[offset]
        local match, start_col, end_col = unpack(vim.fn.matchstrpos(line, subpattern))

        if start_col == -1 then
            break
        end

        match_count = match_count + 1

        local _submatches = vim.fn.matchstrlist(
            { line },
            subpattern,
            { submatches = true }
        )
        vim.print(vim.inspect(_submatches))

        table.insert(text, match)
        merge_submatches(submatches, _submatches[1] and _submatches[1].submatches or {})

        from.col = math.min(from.col, start_col)
        to.lnum = offset
        to.col = end_col
    end

    if match_count < #match_spec.subpatterns then
        return nil
    end

    return {
        text = table.concat(text, "\n"),
        submatches = submatches,
        from = from,
        to = to,
    }
end

--- Like find_at_line but just confirms if the match spec matches at the given line
---@param lines string[]
---@param match_spec terminal-diagnostics._ResolvedMatchSpec
---@param lnum integer
---@return boolean
function patterns.find_at_line_fast(lines, match_spec, lnum)
    local match_count = 0
    lnum = lnum or 1

    for pidx, subpattern in ipairs(match_spec.subpatterns) do
        local offset = lnum + pidx - 1
        local line = lines[offset]
        local _, start_col, _ = unpack(vim.fn.matchstrpos(line, subpattern))

        if start_col == -1 then
            return false
        end

        match_count = match_count + 1
    end

    if match_count < #match_spec.subpatterns then
        return false
    end

    return true
end

--- Parse the subgroups in a pattern and figure out their locations in the
--- matched string
---@param match_string string
---@param spec         terminal-diagnostics.MatchSpec
---@return terminal-diagnostics.SubgroupParseResult
function patterns.parse_subgroups(match_string, spec)
    -- NOTE: This is a horrible solution but there is currently no builtin solution
    -- TODO: Does not work for multiline patterns
    local idx = 1
    local submatches = {}
    local pattern = spec.pattern

    repeat
        -- Find the next unescaped pattern group
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

        table.insert(submatches, { start_col = sub_start_col + 1, end_col = sub_end_col })

        idx = end_col + 1
    until idx > #pattern

    ---@type terminal-diagnostics.SubgroupParseResult
    local results = {}
    local subgroups = require("terminal-diagnostics.matchers").match_spec_keys()

    for _, name in ipairs(subgroups) do
        local group_idx = spec[name]
        local submatch = submatches[group_idx]

        if group_idx and submatch then
            results[name] = submatches[group_idx]
        end
    end

    return results
end

return patterns
