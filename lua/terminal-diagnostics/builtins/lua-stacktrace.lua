local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v^lua(jit)?: (.+)\.lua:(\d+): (.+)$]],
    path = 2,
    lnum = 3,
    message = 4,
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = [[\v\s+(.+)\.lua:(\d+): (in .+)$]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local matcher = HeaderMatcher.new({
    header_spec = header_spec,
    error_spec = error_line_spec,
})

return CommandSpec.new("lua-stacktrace", CommandSpec.CommandKind.Build, matcher)
