local patterns = {}

---@class terminal-diagnostics.EditorPosition
---@field lnum integer
---@field col  integer

---@class terminal-diagnostics.Match
---@field text       string
---@field submatches string[]
---@field from       terminal-diagnostics.EditorPosition
---@field to         terminal-diagnostics.EditorPosition

local function keep_cursor(func)
    local cursor = vim.api.nvim_win_get_cursor(0)

    func()

    vim.api.nvim_win_set_cursor(0, cursor)
end

---@param buffer       integer
---@param spec         terminal-diagnostics.MatchSpec
---@param first_match  terminal-diagnostics.EditorPosition
---@param second_match terminal-diagnostics.EditorPosition
---@return terminal-diagnostics.Match
local function create_match(buffer, spec, first_match, second_match)
    local text = { table.concat(vim.api.nvim_buf_get_text(
        buffer,
        first_match[1] - 1,
        first_match[2] - 1,
        second_match[1] - 1,
        second_match[2],
        {}
    ), "\n") }

    local submatches = vim.fn.matchstrlist(text, spec.regex, { submatches = true })

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

local function find_match_on_line(lnum, col, pattern)
    local match

    keep_cursor(function()
        vim.api.nvim_win_set_cursor(0, { lnum, 0 })
        match = vim.fn.searchpos(pattern, "W")

        while match[1] == lnum do
            match = vim.fn.searchpos(pattern, "W")

            if match[2] >= col then

            end
        end
    end)

    return match
end

---@param buffer integer
---@param spec   terminal-diagnostics.MatchSpec
---@param count  integer?
---@return terminal-diagnostics.Match?
function patterns.find(buffer, spec, count)
    local match
    local _count = count or 1
    local extra_flags = _count > 0 and "W" or "bW" -- TODO: Make wrap configurable
    local pattern = spec.regex

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

function patterns.find_at_cursor(buffer, spec)
    local match
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    col = col + 1
    local first_match = vim.fn.searchpos(spec.regex, "cnbW")

    -- TODO: Allow overriding second condition for multiline patterns
    if first_match[1] == 0 or first_match[1] ~= lnum then
        return
    end

    local second_match = vim.fn.searchpos(spec.regex, "cneW")

    if second_match[1] == 0 or second_match[1] ~= lnum then
        return
    end

    if lnum >= first_match[1] and lnum <= second_match[1] then
        if col >= first_match[2] and col <= second_match[2] then
            match = create_match(buffer, spec, first_match, second_match)
        end
    end

    return match
end

return patterns
