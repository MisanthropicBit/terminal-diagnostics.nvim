---@type terminal-diagnostics.Matcher
---@diagnostic disable-next-line: missing-fields
local python_stacktrace = {}

local utils = require("terminal-diagnostics.utils")
local patterns = require("terminal-diagnostics.matchers.patterns")

local last_match_pos

---@type terminal-diagnostics.MatchSpec
local header_pattern = {
    regex = [[\v^Traceback \(most recent call last\):$]],
}

---@type terminal-diagnostics.MatchSpec
local error_line_pattern = {
    -- FIX: Use of \zs/\ze does not work when creating match
    regex = [[\v^\s+File "(.+)", line (\d+), in .+$]],
    path = 1,
    lnum = 2,
}

function python_stacktrace.name()
    return "python-stacktrace"
end

function python_stacktrace.kind()
    return "stacktrace"
end

function python_stacktrace.match(options)
    local match
    local buffer = options.buffer
    local count = options.count or 1

    -- Cases:
    -- 1. Cursor on header
    -- 2. Cursor on error line
    -- 3. Cursor on neither

    if last_match_pos then
        match = utils.patterns.find_at_cursor(buffer, error_line_pattern.regex)
        last_match_pos = nil
    else
        local on_header = utils.patterns.find_at_cursor(buffer, header_pattern)

        if on_header then
            match = utils.patterns.find(buffer, error_line_pattern.regex, count)
        else
            local on_error_line = utils.patterns.find_at_cursor(buffer, error_line_pattern.regex)

            if on_error_line then
                match = utils.patterns.find(buffer, error_line_pattern.regex)
            else
                utils.patterns.find(buffer, header_pattern.regex)
                match = utils.patterns.find(buffer, error_line_pattern.regex)
            end
        end
    end

    if not match then
        return
    end

    -- TODO: Extract error message. Probably scan forward until we hit a blank
    -- line then assume the previous non-blank line is the error message

    return match, patterns.extract_from_match(error_line_pattern, match)
end

function python_stacktrace.match_start(options)
    local buffer = options.buffer
    local count = options.count or 1
    local header_pos = utils.patterns.find(buffer, header_pattern.regex, count)

    if not header_pos then
        return
    end

    local error_line_pos = utils.patterns.find(buffer, error_line_pattern.regex, count)

    if not error_line_pos then
        last_match_pos = nil
        return
    end

    last_match_pos = error_line_pos

    return last_match_pos
end

return python_stacktrace
