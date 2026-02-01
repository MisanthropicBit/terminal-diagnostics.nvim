local eslint = {}

local utils = require("terminal-diagnostics.utils")
local patterns = require("terminal-diagnostics.parsers.patterns")

local last_match_pos
local header = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})$"
local error_line = "\\v^\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.{-1,})%(\\s\\s+(.*))?$"

function eslint.name()
    return "eslint-stylish"
end

function eslint.kind()
    return PatternKind.Lint
end

---@diagnostic disable-next-line: unused-local
function eslint.match(buffer, lnum, col)
    -- Cases:
    -- 1. Cursor on header
    -- 2. Cursor on error line
    -- 3. Cursor on neither

    local on_header = utils.patterns.find_at_cursor(buffer, header)

    if on_header then
        match = utils.patterns.find(buffer, header, on_header.from.lnum, on_header.from.col)
    end

    local on_error_line = utils.patterns.find_at_cursor(buffer, error_line)

    if on_error_line then
        match = utils.patterns.find(buffer, error_line)
    end

    match = utils.patterns.find(buffer, header)

    -- TODO: Use last_match_pos if set and reset cursor position afterwards

    if not match then
        return
    end

    return patterns.extract_from_match(pattern, match)
end

---@diagnostic disable-next-line: unused-local
function eslint.find_start(buffer, lnum, col)
    local header_pos = vim.fn.searchpos(header, "n")

    if header_pos[1] == 0 then
        return
    end

    local next_line = vim.fn.getline(lnum + 1)
    local idx = vim.fn.match(next_line, error_line, 0, 1) == -1

    if idx == -1 then
        last_match_pos = nil
        return
    end

    last_match_pos = { lnum + 1, idx }

    return last_match_pos
end

return eslint
