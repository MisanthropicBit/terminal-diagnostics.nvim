local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

-- A fallback command spec that looks for the following common patterns:
--
-- * 'path.ts:10'
-- * 'path.ts:10:2'
-- * 'path.ts:10: message'
-- * 'path.ts:10:2: message'
--
-- It does not match
--
-- * 'path.ts'
--
-- as it is too general

local path_pattern = [=[\v(%(%(\/)?%([.A-Za-z0-9-_]+\/)+)?[.A-Za-z0-9-_]+\.\w+)]=]

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = path_pattern .. [=[:(\d+)%(:(\d+))?%(: (.+))?]=],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    message = 4,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("path", CommandSpec.CommandKind.Build, matcher)
