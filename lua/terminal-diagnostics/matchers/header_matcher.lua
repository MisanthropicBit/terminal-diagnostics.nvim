local Matcher = require("terminal-diagnostics.matchers.matcher")
local patterns = require("terminal-diagnostics.patterns")
local matchers = require("terminal-diagnostics.matchers")

-- TODO: Rename to SectionedMatcher or SplitMatcher and take an array of specs
-- that are aggregated on extraction. Covers both eslint-stylish and rustc
-- errors

---@class terminal-diagnostics.HeaderMatcherOptions
---@field header_spec terminal-diagnostics.MatchSpec
---@field error_spec  terminal-diagnostics.MatchSpec

---@class terminal-diagnostics.HeaderMatcher : terminal-diagnostics.Matcher
---@field private header_spec    terminal-diagnostics.MatchSpec
---@field private error_spec     terminal-diagnostics.MatchSpec
---@field private include_header boolean
local HeaderMatcher = setmetatable({}, Matcher)

HeaderMatcher.__index = HeaderMatcher

---@param options terminal-diagnostics.HeaderMatcherOptions
---@return terminal-diagnostics.HeaderMatcher
function HeaderMatcher.new(options)
    local header_matcher = vim.tbl_extend("force", {}, options)

    return setmetatable(header_matcher, HeaderMatcher)
end

---@return terminal-diagnostics.MatchSpec[]
function HeaderMatcher:specs()
    return { self.header_spec, self.error_spec }
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.MatchResult2[]
function HeaderMatcher:match(options)
    local buffer = options.buffer
    local count = options.count or 1

    if self.last_match_pos then
        local spec = self.last_match_type == "header" and self.header_spec or self.error_spec
        local match = patterns.find_at_cursor(buffer, spec)

        if match then
            self.last_match_pos = nil
            self.last_match_type = nil

            return { { spec = spec, match = match } }
        end
    end

    local cursor_result = self:match_at_cursor({ buffer = buffer })

    if #cursor_result > 0 then
        return cursor_result
    end

    local results = {}

    if count > 0 then
        results = self:match_downwards(options)
    else
        results = self:match_upwards(options)
    end

    return results
end

---@private
---@param options terminal-diagnostics.MatchOptions
function HeaderMatcher:match_upwards(options)
    local error_match =
        patterns.find(options.buffer, self.error_spec, options.count)

    if error_match then
        local header_match = patterns.find(options.buffer, self.header_spec, -1)

        if header_match then
            return {
                { spec = self.error_spec,  match = error_match },
                { spec = self.header_spec, match = header_match },
            }
        end
    end

    return {}
end

---@private
---@param options terminal-diagnostics.MatchOptions
function HeaderMatcher:match_downwards(options)
    local header_match =
        patterns.find(options.buffer, self.header_spec, options.count)

    if header_match then
        return { spec = self.header_spec, match = header_match }
    end

    local error_match = patterns.find(options.buffer, self.error_spec, 1)

    if error_match then
        local results = {}
        table.insert(results, { spec = self.error_spec, match = error_match })

        header_match = patterns.find(options.buffer, self.header_spec, -1)

        if header_match then
            table.insert(results, { spec = self.header_spec, match = header_match })
        end

        return results
    end

    return {}
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.Match?
function HeaderMatcher:find_match_start(options)
    local buffer = options.buffer
    local count = options.count or 1
    local header_match = patterns.find(buffer, self.header_spec, count)
    local error_match = patterns.find(buffer, self.error_spec, count)

    if header_match then
        if error_match then
            if count > 0 then
                if header_match.from.lnum > error_match.from.lnum then
                    self.last_match_pos = error_match
                    self.last_match_type = "error"
                elseif header_match.from.lnum < error_match.from.lnum then
                    self.last_match_pos = header_match
                    self.last_match_type = "header"
                end
            elseif count < 0 then
                if header_match.from.lnum > error_match.from.lnum then
                    self.last_match_pos = header_match
                    self.last_match_type = "header"
                elseif header_match.from.lnum < error_match.from.lnum then
                    self.last_match_pos = error_match
                    self.last_match_type = "error"
                end
            end
        else
            self.last_match_pos = header_match
            self.last_match_type = "header"
        end
    elseif error_match then
        self.last_match_pos = error_match
        self.last_match_type = "error"
    end

    return self.last_match_pos
end

---@param options terminal-diagnostics.MatchAtCursorOptions
function HeaderMatcher:match_at_cursor(options)
    local buffer = options.buffer
    local results = {}
    local header_match = patterns.find_at_cursor(buffer, self.header_spec)

    if header_match then
        -- If on a header that should be included (has info), just return that
        return { { spec = self.header_spec, match = header_match } }
    else
        local error_match = patterns.find_at_cursor(buffer, self.error_spec)

        if error_match then
            -- If including the header, find it and add it
            local _header_match = patterns.find(buffer, self.header_spec, -1)

            if _header_match then
                table.insert(results, { spec = self.header_spec, match = _header_match })
            end

            table.insert(results, { spec = self.error_spec, match = error_match })
        end
    end

    return results
end

function HeaderMatcher:extract_values(results)
    -- TODO: Either find header in buffer now or do it in match. If latter
    -- solution, then we need to expand MatchSpec to contain more information
    ---@diagnostic disable-next-line: missing-fields
    local match_data = {} ---@type terminal-diagnostics.MatchResult

    for _, result in ipairs(results) do
        local data = matchers.extract_from_match(result.spec, result.match)

        match_data = vim.tbl_extend("force", match_data, data)
    end

    return match_data
end

return HeaderMatcher
