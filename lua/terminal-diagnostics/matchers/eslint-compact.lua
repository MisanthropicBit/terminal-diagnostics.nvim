local generators = require("terminal-diagnostics.matchers.generators")

local error_line = {
    regex = [[\v^(.+):\sline\s(\d+),\scol\s(\d+),\s(Error|Warning|Info)\s-\s(.+)(\s\((.+)\))?$]],
    file = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    message = 5,
    code = 6,
}

return generators.generate_simple_matcher({
    name = "eslint-compact",
    kind = "lint",
    pattern = error_line,
})
