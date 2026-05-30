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

function Matcher:resolve_specs() end

--- Prepare a match spec for use in parsing
---@param spec terminal-diagnostics.MatchSpec
---@return terminal-diagnostics._ResolvedMatchSpec
function Matcher.resolve_spec(spec)
    local resolved_spec = spec

    resolved_spec.multiline = spec.pattern:find([[\n]], 1, true)
    resolved_spec.subpatterns = vim.split(spec.pattern, [[\n]], { plain = true })

    if #resolved_spec.subpatterns > 1 then
        local has_magic = vim.startswith(resolved_spec.subpatterns[1], "\\v")

        if has_magic then
            for idx, subpattern in ipairs(resolved_spec.subpatterns) do
                resolved_spec.subpatterns[idx] = "\\v" .. subpattern
            end
        end
    end

    return resolved_spec
end

---@param results terminal-diagnostics.MatchResult2[]
---@return terminal-diagnostics.MatchResult
function Matcher:extract_values(results) end

return Matcher
