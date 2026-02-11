local generators = require("terminal-diagnostics.matchers.generators")

local function resolve_severity(severity)
    if severity == "help" or severity == "note" then
        return "info"
    end

    return severity
end

---@type terminal-diagnostics.MatchSpec
local error_line = {
    regex = [[\v^(error|warning|help|note)%(\[(.+)\])?: (.+)\n\s+--\> (.+):(\d+):(\d+)]],
    severity = {
        index = 1,
        resolve = resolve_severity,
    },
    code = 2,
    message = 3,
    path = 4,
    lnum = 5,
    col = 6,
}

local rustc = generators.generate_simple_matcher({
    name = "rustc",
    kind = "build",
    pattern = error_line,
})

return rustc
