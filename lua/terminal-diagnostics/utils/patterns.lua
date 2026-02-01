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
---@param pattern      string
---@param first_match  terminal-diagnostics.EditorPosition
---@param second_match terminal-diagnostics.EditorPosition
---@return terminal-diagnostics.Match
local function create_match(buffer, pattern, first_match, second_match)
    local match = vim.api.nvim_buf_get_text(
        buffer,
        first_match[1] - 1,
        first_match[2] - 1,
        second_match[1] - 1,
        second_match[2],
        {}
    )
    local submatches = vim.fn.matchstrlist(match, pattern, { submatches = true })

    return {
        text = match,
        submatches = submatches[1].submatches,
        from = {
            lnum = first_match[1],
            col = first_match[2],
        },
        to = {
            lnum = second_match[1],
            col = second_match[2],
        },
    }
end

---@param buffer integer
---@param pattern string
---@param count integer?
---@return terminal-diagnostics.Match?
function patterns.find(buffer, pattern, count)
    local match
    local _count = count or 1
    local extra_flags = count > 0 and "" or "b"

    keep_cursor(function()
        local first_match = vim.fn.searchpos(pattern, "z" .. extra_flags)

        if first_match[1] == 0 and first_match[2] == 0 then
            return
        end

        local second_match = vim.fn.searchpos(pattern, "ce")

        if second_match[1] == 0 and second_match[2] == 0 then
            return
        end

        match = create_match(buffer, pattern, first_match, second_match)
    end)

    return match
end

function patterns.find_at_cursor(buffer, pattern)
    local match

    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    col = col + 1
    local first_match = vim.fn.searchpos(pattern, "cbzn")

    if first_match[1] == 0 and first_match[2] == 0 then
        return
    end

    local second_match = vim.fn.searchpos(pattern, "ceWn")

    if second_match[1] == 0 and second_match[2] == 0 then
        return
    end

    if lnum >= first_match[1] and lnum <= second_match[1] then
        if col >= first_match[2] and col <= second_match[2] then
            match = create_match(buffer, pattern, first_match, second_match)
        end
    end

    return match
end

return patterns
