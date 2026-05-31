local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v\s*FAIL\s+(\S+)]],
    path = 1,
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = [[\vat \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local matcher = SimpleMatcher.new({ specs = { header_spec, error_line_spec } })

return CommandSpec.new(
    "jest",
    CommandSpec.CommandKind.Test,
    matcher,
    { has_context = true }
)
