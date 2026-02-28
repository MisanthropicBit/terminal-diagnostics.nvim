local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})$"
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = "\\v^\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.{-1,})%(\\s\\s+(.*))?$",
    lnum = 1,
    col = 2,
    severity = 3,
    message = 4,
    code = 5,
}

return generators.generate_header_matcher({
    name = "eslint-stylish",
    kind = "lint",
    header_spec = header_spec,
    error_spec = error_line_spec,
})
