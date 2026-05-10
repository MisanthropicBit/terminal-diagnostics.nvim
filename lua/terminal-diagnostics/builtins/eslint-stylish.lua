local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")

local error_spec_pattern = [[\s+(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]]

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})\\n" .. error_spec_pattern,
    path = 1,
    path_kind = "absolute",
    multiline = true,
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    pattern = [[\v^]] .. error_spec_pattern,
    lnum = 1,
    col = 2,
    severity = 3,
    message = 4,
    code = 5,
}

local matcher = HeaderMatcher.new({
    header_spec = header_spec,
    error_spec = error_spec,
})

return CommandSpec.new("eslint-stylish", CommandSpec.CommandKind.Lint, matcher)
