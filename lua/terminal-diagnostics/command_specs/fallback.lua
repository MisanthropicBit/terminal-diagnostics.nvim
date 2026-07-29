local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

-- A fallback command spec that looks for a path optionally followed by a line
-- number and/or column number

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    -- TODO: Change to match: 'path:13:9: message'
    pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=],
    path_kind = "absolute",
    path = 1,
    lnum = 2,
    col = 3,
    message = 4,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("fallback", CommandSpec.CommandKind.Build, matcher)
