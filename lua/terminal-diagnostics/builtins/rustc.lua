local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

---@param severity string
---@return string
local function resolve_severity(severity)
    if severity == "help" or severity == "note" then
        return "info"
    end

    return severity
end

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [[\v^(error|warning|help|note)%(\[(.+)\])?: (.+)\n\s+--\> (.+):(\d+):(\d+)]],
    path_kind = "relative",
    multiline = true,
    severity = {
        index = 1,
        resolve = resolve_severity,
    },
    code = 2,
    message = 3,
    path = 4,
    lnum = 5,
    col = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })

return CommandSpec.new("rustc", CommandSpec.CommandKind.Build, matcher)
