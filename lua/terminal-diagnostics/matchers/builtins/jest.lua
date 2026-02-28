local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v\s*FAIL\s+(\S+)]],
    path = 1,
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = [[\vat \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

return generators.generate_header_matcher({
    name = "jest",
    kind = "test",
    header_spec = header_spec,
    error_spec = error_line_spec,
})
