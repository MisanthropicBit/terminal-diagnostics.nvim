local generators = require("terminal-diagnostics.matchers.generators")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v^lua(jit)?: (.+)\.lua:(\d+): (.+)$]],
    path = 2,
    lnum = 3,
    message = 4,
}

---@type terminal-diagnostics.MatchSpec
local error_line_spec = {
    pattern = [[\v\s+(.+)\.lua:(\d+): (in .+)$]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local lua_stacktrace = generators.generate_header_matcher({
    name = "lua-stacktrace",
    kind = "stacktrace",
    header_spec = header_spec,
    error_spec = error_line_spec,
})

return lua_stacktrace
