local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header = {
    regex = [[\v^lua(jit)?: (.+)\.lua:(\d+): (.+)$]],
    path = 2,
    lnum = 3,
    message = 4,
}

---@type terminal-diagnostics.MatchSpec
local error_line = {
    regex = [[\v\s+(.+)\.lua:(\d+): (in .+)$]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local jest = generators.generate_header_matcher({
    name = "lua-stacktrace",
    kind = "stacktrace",
    header_pattern = header,
    error_line_pattern = error_line,
})

return jest
