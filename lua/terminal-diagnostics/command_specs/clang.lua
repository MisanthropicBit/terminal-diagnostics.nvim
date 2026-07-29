-- Header pattern for ninja
-- local header_pattern = [[\vFAILED:\s+\[code\=\d+\] %(\/)?%([.A-Za-z0-9-_]+\/)+[.A-Za-z0-9-_]+\.\w+\n.+\n]] .. error_pattern

local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")
local SimpleParser = require("terminal-diagnostics.parsers.simple_parser")

local error_pattern = [[\v^(%(%(\/)?%([.A-Za-z0-9-_+]+\/)+[.A-Za-z0-9-_+]+\.\w+)):(\d+):(\d+): (\w+): (.+)$]]

local error_spec = {
    pattern = error_pattern,
    path_kind = "absolute",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
}

local matcher = SimpleMatcher.new({ specs = { error_spec }})
local parser = SimpleParser.new()

parser:extend({
    ---@param self terminal-diagnostics.parser.SimpleMatcherParser
    ---@param line string
    ---@return boolean
    ---@diagnostic disable-next-line: unused-local
    is_context_line = function(self, line)
        local _, start_col, _ = unpack(vim.fn.matchstrpos(line, [[\v%(\s+%(\d+))?\s+\|]]))

        return start_col ~= -1
    end,
})

return CommandSpec.new(
    "clang",
    CommandSpec.CommandKind.Build,
    matcher,
    { parser = parser }
)
