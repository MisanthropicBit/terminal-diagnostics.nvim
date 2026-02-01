local matchers = {}

---@class terminal-diagnostics.MatchAtCursorOptions
---@field buffer integer

---@class terminal-diagnostics.MatchOptions: terminal-diagnostics.MatchAtCursorOptions
---@field lnum   integer
---@field col    integer
---@field count  integer?

---@class terminal-diagnostics.Matcher
---@field name fun(): string
---@field kind fun(): terminal-diagnostics.PatternKind
---@field match fun(options: terminal-diagnostics.MatchOptions): terminal-diagnostics.Match?, terminal-diagnostics.MatchResult?
---@field match_start fun(options: terminal-diagnostics.MatchOptions): terminal-diagnostics.Match?
---@field match_at_cursor fun(options: terminal-diagnostics.MatchAtCursorOptions): terminal-diagnostics.Match?, terminal-diagnostics.MatchResult?

---@return terminal-diagnostics.Matcher[]
function matchers.get_all()
    return {
        require("terminal-diagnostics.matchers.tsc"),
        require("terminal-diagnostics.matchers.jest"),
        require("terminal-diagnostics.matchers.python-stacktrace"),
        require("terminal-diagnostics.matchers.pytest"),
        require("terminal-diagnostics.matchers.gcc"),
        require("terminal-diagnostics.matchers.lua-stacktrace"),
    }
end

return matchers
