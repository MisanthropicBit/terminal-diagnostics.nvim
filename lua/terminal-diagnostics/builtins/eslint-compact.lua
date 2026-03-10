local CommandSpec = require("terminal-diagnostics.command_spec")
local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [[\v^(.+):\sline\s(\d+),\scol\s(\d+),\s(Error|Warning|Info)\s-\s(.+)(\s\((.+)\))?$]],
    path_kind = "relative",
    file = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
    code = 6,
}

local matcher = generators.generate_simple_matcher({ specs = { match_spec } })

-- TODO: Split into 'eslint' and 'compact'?
return CommandSpec.new("eslint-compact", CommandSpec.CommandKind.Lint, matcher)
