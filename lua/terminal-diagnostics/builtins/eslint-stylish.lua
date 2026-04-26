local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})$",
    path = 1,
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    pattern = [[\v^(.+):\sline\s(\d+),\scol\s(\d+),\s(Error|Warning|Info)\s-\s(.+)(\s\((.+)\))?$]],
    path_kind = "relative",
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
    code = 6,
}

local matcher = HeaderMatcher.new({
    header_spec = header_spec,
    error_spec = error_spec,
})

return CommandSpec.new("eslint-stylish", CommandSpec.CommandKind.Lint, matcher)
