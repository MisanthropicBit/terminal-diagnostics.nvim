local generators = require("terminal-diagnostics.matchers.generators")

local header = {
    regex = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})$"
}

local error_line = {
    regex = "\\v^\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.{-1,})%(\\s\\s+(.*))?$",
    lnum = 1,
    col = 2,
    severity = 3,
    message = 4,
    code = 5,
}

return generators.generate_header_matcher({
    name = "eslint-stylish",
    kind = "lint",
    header_pattern = header,
    error_line_pattern = error_line,
})
