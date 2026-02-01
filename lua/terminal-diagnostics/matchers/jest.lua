local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header = {
    regex = [[\v\s*FAIL\s+(\S+)]],
    path = 1,
}

---@type terminal-diagnostics.MatchSpec
local error_line = {
    regex = [[\vat \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local jest = generators.generate_header_matcher({
    name = "jest",
    kind = "test",
    header_pattern = header,
    error_line_pattern = error_line,
})

return jest
