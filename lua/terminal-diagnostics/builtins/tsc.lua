local CommandSpec = require("terminal-diagnostics.command_spec")
local generators = require("terminal-diagnostics.matchers.generators")

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

local matcher = generators.generate_simple_matcher({ specs = { match_spec } })

return CommandSpec.new("tsc", CommandSpec.CommandKind.Build, matcher)
