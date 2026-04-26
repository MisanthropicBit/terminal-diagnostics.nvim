local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

-- require("terminal-diagnostics.utils").patterns.find(361, { pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=], path_kind = "relative", path = 1, lnum = 2, col = 3, severity = 4, code = 5, message = 6 }, 1)

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("tsc", CommandSpec.CommandKind.Build, matcher)
