-- TODO: Rename to 'search'?
local patterns = {}

---@class terminal-diagnostics.FindOptions
---@field count integer?
---@field wrap  boolean?

---@class terminal-diagnostics.SubGroupResult
---@field start_lnum integer
---@field start_col  integer
---@field end_lnum   integer
---@field end_col    integer

---@class terminal-diagnostics.SubgroupParseResult
---@field path     terminal-diagnostics.SubGroupResult?
---@field lnum     terminal-diagnostics.SubGroupResult?
---@field col      terminal-diagnostics.SubGroupResult?
---@field severity terminal-diagnostics.SubGroupResult?
---@field message  terminal-diagnostics.SubGroupResult?
---@field code     terminal-diagnostics.SubGroupResult?

local function keep_cursor(func)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local result = func()

    vim.api.nvim_win_set_cursor(0, cursor)

    return result
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

---@param buffer      integer
---@param spec        terminal-diagnostics.MatchSpec
---@param start_match terminal-diagnostics.Position
---@param end_match   terminal-diagnostics.Position
---@return terminal-diagnostics.Match
local function create_match(buffer, spec, start_match, end_match)
    -- FIX: first_match and second_match are not Positions
    local text = {
        table.concat(
            vim.api.nvim_buf_get_text(
                buffer,
                start_match[1] - 1,
                start_match[2] - 1,
                end_match[1] - 1,
                end_match[2],
                {}
            ),
            "\n"
        ),
    }

    local submatches = vim.fn.matchstrlist(text, spec.pattern, { submatches = true })
    local merged_submatches = {}
    merge_submatches(merged_submatches, submatches[1] and submatches[1].submatches or {})

    return {
        text = text[1],
        submatches = merged_submatches,
        from = {
            lnum = start_match[1] - 1,
            col = start_match[2] - 1,
        },
        to = {
            lnum = end_match[1] - 1,
            col = end_match[2],
        },
        spec = spec,
    }
end

--- Find a spec's pattern in a buffer. Does not find matches that the cursor is
--- already inside of
---@param buffer  integer
---@param spec    terminal-diagnostics.MatchSpec
---@param options terminal-diagnostics.FindOptions?
---@return terminal-diagnostics.Match?
function patterns.find(buffer, spec, options)
    local match
    local pattern = spec.pattern
    local _options = vim.tbl_extend("keep", options or {}, { wrap = false, count = 1 })
    local flags = (_options.count > 0 and "" or "b") .. (_options.wrap and "" or "W")

    -- TODO: Does this find something on the same line as a valid pattern
    keep_cursor(function()
        local first_match = vim.fn.searchpos(pattern, flags)

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

---@param spec terminal-diagnostics.ResolvedMatchSpec
local function find_at_cursor_singleline(spec, lnum, col)
    local start_match = vim.fn.searchpos(spec.pattern, "cnbW")
    local start_lnum, start_col = unpack(start_match)

    if start_lnum ~= lnum then
        return
    end

    local end_match = vim.fn.searchpos(spec.pattern, "cneW")
    local end_lnum, end_col = unpack(end_match)

    if end_lnum ~= lnum then
        return
    end

    if lnum >= start_lnum and lnum <= end_lnum then
        if col >= start_col and col <= end_col then
            return start_match, end_match
        end
    end
end

---@param spec terminal-diagnostics.ResolvedMatchSpec
local function find_at_cursor_multiline(spec, lnum, col)
    local start_match = vim.fn.searchpos(spec.pattern, "cnbW")
    local start_lnum, start_col = unpack(start_match)
    local spec_lines = #spec.subpatterns

    if start_lnum == 0 then
        return
    end

    if lnum >= start_lnum and lnum <= start_lnum + spec_lines - 1 then
        local _end_col = #spec.subpatterns[#spec.subpatterns]

        if col >= start_col and col <= _end_col then
            local end_match = keep_cursor(function()
                vim.api.nvim_win_set_cursor(0, { start_lnum, start_col })

                return vim.fn.searchpos(spec.pattern, "cneW")
            end)

            return start_match, end_match
        end
    end
end

--- Find a spec's pattern at the cursor position
---@param buffer integer
---@param spec terminal-diagnostics.ResolvedMatchSpec
---@return terminal-diagnostics.Match?
function patterns.find_at_cursor(buffer, spec)
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    col = col + 1
    local start_match, end_match

    if spec.multiline then
        start_match, end_match = find_at_cursor_multiline(spec, lnum, col)
    else
        start_match, end_match = find_at_cursor_singleline(spec, lnum, col)
    end

    if start_match and end_match then
        return create_match(buffer, spec, start_match, end_match)
    end
end

--- Like find_at_line but just confirms if the match spec matches at the given line
---@param lines string[]
---@param match_spec terminal-diagnostics.ResolvedMatchSpec
---@param lnum integer
---@return boolean
local function find_at_line_fast(lines, match_spec, lnum)
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

--- Find and return the line number where a a spec's pattern matches or -1 if
--- there is no match
---@param lines string[]
---@param match_spec terminal-diagnostics.ResolvedMatchSpec
---@param start_lnum integer?
---@return integer
function patterns.find_in_lines(lines, match_spec, start_lnum)
    for lnum = start_lnum or 1, #lines do
        if find_at_line_fast(lines, match_spec, lnum) then
            return lnum - 1
        end
    end

    return -1
end

--- Finds and returns a full match in a list of lines
---@param lines string[]
---@param match_spec terminal-diagnostics.ResolvedMatchSpec
---@param lnum integer?
---@return terminal-diagnostics.Match?
function patterns.find_at_line(lines, match_spec, lnum)
    local text = {}
    local submatches = {}
    local from = { lnum = -1, col = math.huge }
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

        table.insert(text, match)
        merge_submatches(submatches, _submatches[1] and _submatches[1].submatches or {})

        from.lnum = lnum - 1
        from.col = math.min(from.col, start_col)
        to.lnum = offset - 1
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
        spec = match_spec,
    }
end

--- Parse the subgroups in a pattern and figure out their locations in the
--- matched string
---@param match_string string
---@param spec         terminal-diagnostics.ResolvedMatchSpec
---@return terminal-diagnostics.SubgroupParseResult
function patterns.parse_subgroups(match_string, spec)
    -- NOTE: This is a horrible solution but there is currently no builtin solution
    local submatches = {}
    local lines = vim.split(match_string, "\n", { plain = true, trimempty = true })

    assert(#lines == #spec.subpatterns)

    for idx = 1, #lines do
        local offset = 0
        local line = lines[idx]
        local subpattern = spec.subpatterns[idx]

        repeat
            -- Find the next unescaped pattern group
            local _, start_col, end_col = unpack(
                vim.fn.matchstrpos(
                    subpattern,
                    [[\v(\\|\%)@<!\(.{-}(\\|\%)@<!\)]],
                    offset,
                    1
                )
            )

            if start_col == -1 then
                break
            end

            -- Reconstruct the pattern with match markers around the group that we found
            local group_pattern = ("%s\\zs%s\\ze%s"):format(
                subpattern:sub(1, start_col),
                subpattern:sub(start_col + 1, end_col),
                subpattern:sub(end_col + 1)
            )

            local _, sub_start_col, sub_end_col =
                unpack(vim.fn.matchstrpos(line, group_pattern))

            table.insert(submatches, {
                start_lnum = idx,
                start_col = sub_start_col,
                end_lnum = idx,
                end_col = sub_end_col,
            })

            offset = end_col + 1
        until offset > #subpattern
    end

    ---@type terminal-diagnostics.SubgroupParseResult
    local results = {}
    local matchers = require("terminal-diagnostics.matchers")
    local spec_keys = matchers.match_spec_keys()

    for _, name in ipairs(spec_keys) do
        local group_idx = matchers.resolve_spec_index(spec[name])
        local submatch = submatches[group_idx]

        if group_idx and submatch then
            results[name] = submatches[group_idx]
        end
    end

    return results
end

return patterns
