local Matcher = require("terminal-diagnostics.matchers.matcher")
local matchers = require("terminal-diagnostics.matchers")
local utils = require("terminal-diagnostics.utils")

---@class (exact) terminal-diagnostics.SimpleMatcherOptions
---@field specs terminal-diagnostics.MatchSpec[]

--- A simple matcher thats matches single lines or contiguous multi-line error
--- messages
---@class terminal-diagnostics.SimpleMatcher : terminal-diagnostics.Matcher
---@field protected _specs terminal-diagnostics.MatchSpec[]
local SimpleMatcher = setmetatable({}, Matcher)

SimpleMatcher.__index = SimpleMatcher

---@param options terminal-diagnostics.SimpleMatcherOptions
---@return terminal-diagnostics.SimpleMatcher
function SimpleMatcher.new(options)
    return setmetatable({ _specs = options.specs }, SimpleMatcher)
end

---@return terminal-diagnostics.MatchSpec[]
function SimpleMatcher:specs()
    return self._specs
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.MatchResult2[]
function SimpleMatcher:match(options)
    local match
    local _options = options or {}
    local count = _options.count or 1

    for _, spec in ipairs(self:specs()) do
        if self.last_match_pos then
            match = utils.patterns.find_at_cursor(_options.buffer, spec)

            if match then
                self.last_match_pos = nil

                return { spec = spec, match = match }
            end
        else
            match = utils.patterns.find(_options.buffer, spec, count)

            if match then
                return { spec = spec, match = match }
            end
        end
    end

    return {}
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.Match?
function SimpleMatcher:find_match_start(options)
    local pos ---@type terminal-diagnostics.Match?
    local count = options.count or 1

    for _, spec in ipairs(self._specs) do
        pos = utils.patterns.find(options.buffer, spec, count)
        self.last_match_pos = pos

        if pos then
            break
        end
    end

    return pos
end

---@param options terminal-diagnostics.MatchAtCursorOptions
function SimpleMatcher:match_at_cursor(options)
    local match

    for _, spec in ipairs(self._specs) do
        match = utils.patterns.find_at_cursor(options.buffer, spec)

        if match then
            return { { spec = spec, match = match } }
        end
    end

    return {}
end

function SimpleMatcher:resolve_specs()
    for _, spec in ipairs(self:specs()) do
        Matcher.resolve_spec(spec)
    end
end

function SimpleMatcher:extract_values(results)
    if #results ~= 1 then
        error(
            ("SimpleMatcher:extract_values expected only one result but got '%d'"):format(
                #results
            )
        )
    end

    return matchers.extract_from_match(results[1].spec, results[1].match)
end

return SimpleMatcher
