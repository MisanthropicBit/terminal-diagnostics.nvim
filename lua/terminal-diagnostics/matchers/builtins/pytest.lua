local generators = require("terminal-diagnostics.matchers.generators")

-- TODO: Might be different given e.g. --quiet
-- TODO: Need several header patterns if --no-header/--no-summary is given
---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = "=========================== test session starts ============================",
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = "\\v(.*\\.py):(\\d+): (.+)?",
    path_kind = "file",
    path = 1,
    lnum = 2,
    -- severity = "ERROR",
    message = 3,
}

return generators.generate_header_matcher({
    name = "pytest",
    kind = "test",
    header_spec = header_spec,
    error_spec = error_line_spec
})
