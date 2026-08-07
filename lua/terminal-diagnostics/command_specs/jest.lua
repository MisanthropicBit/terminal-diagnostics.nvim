local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")
local HeaderParser = require("terminal-diagnostics.parsers.header_parser")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v\s*(FAIL)\s+(\S+)]], -- TODO: Can we expand header pattern?
    severity = {
        index = 1,
        resolve = function(severity)
            if severity == "FAIL" then
                return "ERROR"
            end

            return "INFO"
        end
    },
    path = 2,
    path_kind = "relative",
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    pattern = [[\v\s+at \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "absolute",
    lnum = 2,
    col = 3,
}

local matcher = HeaderMatcher.new({ header_spec = header_spec, error_spec = error_spec })
local parser = HeaderParser.new()

function parser:is_context_line(line, spec)
    -- Only the header spec has context lines
    if spec.pattern == error_spec.pattern then
        return false
    end

    local _, start_col, _ = unpack(vim.fn.matchstrpos(line, error_spec.pattern))

    return start_col == -1
end

return CommandSpec.new(
    "jest",
    CommandSpec.CommandKind.Test,
    matcher,
    { parser = parser }
)
