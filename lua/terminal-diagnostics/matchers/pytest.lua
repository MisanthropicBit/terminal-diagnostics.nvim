local generators = require("terminal-diagnostics.matchers.generators")

-- TODO: Might be different given e.g. --quiet
-- TODO: Need several header patterns if --no-header/--no-summary is given
local header_pattern = {
    regex = "=========================== test session starts ============================",
}

local error_line_pattern = {
    regex = "\\v(.*\\.py):(\\d+): (.+)?",
    path_kind = "file",
    path = 1,
    lnum = 2,
    -- severity = "ERROR",
    message = 3,
}

return generators.generate_header_matcher({
    name = "pytest",
    kind = "test",
    header_pattern = header_pattern,
    error_line_pattern = error_line_pattern
})
