---@class terminal-diagnostics.Matcher
---@field protected last_match_pos integer?
local Matcher = {}

Matcher.__index = Matcher

---@return terminal-diagnostics.Matcher
function Matcher.new()
    return setmetatable({}, Matcher)
end

function Matcher.validate(value)
    vim.validate("matcher", value, function(maybe_matcher)
        return getmetatable(maybe_matcher) == Matcher
    end, "a Matcher class instance")
end

---@return terminal-diagnostics.ResolvedMatchSpec[]
function Matcher:specs()
    return {}
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.MatchResult2[]
---@diagnostic disable-next-line: unused-local
function Matcher:match(options)
    return {}
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.Match?
---@diagnostic disable-next-line: unused-local
function Matcher:find_match_start(options) end

---@param options terminal-diagnostics.MatchAtCursorOptions
---@return terminal-diagnostics.MatchResult2[]
---@diagnostic disable-next-line: unused-local
function Matcher:match_at_cursor(options)
    return {}
end

function Matcher:resolve_specs()
    for _, spec in ipairs(self:specs()) do
        Matcher.resolve_spec(spec)
    end
end

--- Prepare a match spec for use in parsing
---@param spec terminal-diagnostics.MatchSpec
---@return terminal-diagnostics.ResolvedMatchSpec
function Matcher.resolve_spec(spec)
    local resolved_spec = spec

    ---@diagnostic disable-next-line: inject-field
    resolved_spec.multiline = spec.pattern:find([[\n]], 1, true) ~= nil

    ---@diagnostic disable-next-line: inject-field
    resolved_spec.subpatterns = vim.split(spec.pattern, [[\n]], { plain = true })

    if #resolved_spec.subpatterns > 1 then
        local has_magic = vim.startswith(resolved_spec.subpatterns[1], "\\v")

        if has_magic then
            for idx, subpattern in ipairs(resolved_spec.subpatterns) do
                if idx ~= 1 then
                    resolved_spec.subpatterns[idx] = "\\v" .. subpattern
                end
            end
        end
    end

    ---@cast resolved_spec terminal-diagnostics.ResolvedMatchSpec
    return resolved_spec
end

---@param results terminal-diagnostics.MatchResult2[]
---@return terminal-diagnostics.MatchResult
---@diagnostic disable-next-line: unused-local
function Matcher:extract_values(results)
    return {}
end

return Matcher
