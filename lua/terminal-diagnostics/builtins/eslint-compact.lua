local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [[\v^(.+):\sline\s(\d+),\scol\s(\d+),\s(Error|Warning|Info)\s-\s(.+)(\s\((.+)\))?$]],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
    code = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("eslint-compact", CommandSpec.CommandKind.Lint, matcher)
