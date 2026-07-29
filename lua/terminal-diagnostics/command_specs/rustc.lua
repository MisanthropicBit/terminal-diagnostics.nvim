local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")
local SimpleParser = require("terminal-diagnostics.parsers.simple_parser")

---@param severity string
---@return string
local function resolve_severity(severity)
    if severity == "help" or severity == "note" then
        return "info"
    end

    return severity
end

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [[\v^(error|warning|help|note)%(\[(.+)\])?: (.+)\n\s+--\> (.+):(\d+):(\d+)]],
    path_kind = "relative",
    severity = {
        index = 1,
        resolve = resolve_severity,
    },
    code = 2,
    message = 3,
    path = 4,
    lnum = 5,
    col = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })
local parser = SimpleParser.new()

parser:extend({
    ---@param self terminal-diagnostics.parser.SimpleMatcherParser
    ---@param line string
    ---@return boolean
    ---@diagnostic disable-next-line: unused-local
    is_context_line = function(self, line)
        local _, start_col, _ = unpack(vim.fn.matchstrpos(line, [[\v%(\s+%(\d+))?\s+\|]]))

        if start_col ~= -1 then
            return true
        end

        _, start_col, _ = unpack(vim.fn.matchstrpos(line, [[\v\s+\= .+$]]))

        return start_col ~= -1
    end,
})

return CommandSpec.new(
    "rustc",
    CommandSpec.CommandKind.Build,
    matcher,
    { parser = parser }
)
