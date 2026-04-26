---@class terminal-diagnostics.Matcher
---@field protected last_match_pos integer?
local Matcher = {}

Matcher.__index = Matcher

---@return terminal-diagnostics.Matcher
function Matcher.new()
    return setmetatable({}, Matcher)
end

---@return terminal-diagnostics.MatchSpec[]
function Matcher:specs()
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.MatchResult2[]
function Matcher:match(options) end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.Match?
function Matcher:find_match_start(options) end

---@param options terminal-diagnostics.MatchAtCursorOptions
---@return terminal-diagnostics.MatchResult2[]
function Matcher:match_at_cursor(options) end

---@param results terminal-diagnostics.MatchResult2[]
---@return terminal-diagnostics.MatchResult
function Matcher:extract_values(results) end

return Matcher
