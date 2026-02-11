local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header_pattern = {
    regex = [[\v^Traceback \(most recent call last\):$]],
}

---@type terminal-diagnostics.MatchSpec
local error_line_pattern = {
    -- FIX: Use of \zs/\ze does not work when creating match
    regex = [[\v^\s+File "(.+)", line (\d+), in .+$]],
    path = 1,
    lnum = 2,
}

return generators.generate_header_matcher({
    name = "python-stacktrace",
    kind = "stacktrace",
    header_pattern = header_pattern,
    error_line_pattern = error_line_pattern,
})
