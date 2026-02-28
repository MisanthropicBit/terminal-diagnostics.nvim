local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = "\\v^(.{-}):(\\d+):(\\d*):?\\s+%(fatal\\s+)?(warning|error):\\s+(.*)$",
    path_kind = "unknown",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
}

return generators.generate_simple_matcher({
    name = "gcc",
    kind = "build",
    pattern = error_line_spec,
})
