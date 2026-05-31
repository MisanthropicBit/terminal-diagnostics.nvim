local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v^Traceback \(most recent call last\):$]],
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    -- FIX: Use of \zs/\ze does not work when creating match
    pattern = [[\v^\s+File "(.+)", line (\d+), in .+$]],
    path = 1,
    lnum = 2,
}

local matcher = HeaderMatcher.new({ header_spec = header_spec, error_spec = error_spec })

return CommandSpec.new("python-stacktrace", CommandSpec.CommandKind.Build, matcher)
