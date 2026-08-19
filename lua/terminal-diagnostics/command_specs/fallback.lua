local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

-- A fallback command spec that looks for the following common patterns:
--
-- * 'path.ts: message'
-- * 'path.ts:10: message'
-- * 'path.ts:10:2: message'

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [=[\v(%(%(\/)?%([.A-Za-z0-9-_]+\/)+)?[.A-Za-z0-9-_]+\.\w+):%((\d+)%(:(\d+))?:)? (.+)]=],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    message = 4,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("fallback", CommandSpec.CommandKind.Build, matcher)
