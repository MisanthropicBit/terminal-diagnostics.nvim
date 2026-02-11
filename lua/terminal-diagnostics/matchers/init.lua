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

local cached_matchers

---@param filter string[]?
---@return terminal-diagnostics.Matcher[]
function matchers.get_all(filter)
    return {
        require("terminal-diagnostics.matchers.tsc"),
        require("terminal-diagnostics.matchers.eslint-compact"),
        require("terminal-diagnostics.matchers.eslint-stylish"),
        require("terminal-diagnostics.matchers.jest"),
        require("terminal-diagnostics.matchers.python-stacktrace"),
        require("terminal-diagnostics.matchers.pytest"),
        require("terminal-diagnostics.matchers.gcc"),
        require("terminal-diagnostics.matchers.lua-stacktrace"),
        require("terminal-diagnostics.matchers.rustc"),
    }
end

---@return string[]
function matchers.match_spec_keys()
    return { "path", "lnum", "col", "severity", "code", "message" }
end

return matchers
