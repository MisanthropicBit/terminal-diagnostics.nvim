local matcher_generators = {}

local utils = require("terminal-diagnostics.utils")
local patterns = require("terminal-diagnostics.matchers.patterns")

-- TODO: Support multiple error formats for generators

---@class terminal-diagnostics.HeaderMatcherOptions
---@field name               string
---@field kind               string
---@field header_pattern     terminal-diagnostics.MatchSpec
---@field error_line_pattern terminal-diagnostics.MatchSpec

---@param spec terminal-diagnostics.MatchSpec
---@return boolean
local function spec_has_info(spec)
    local has_info = spec.path
        or spec.lnum
        or spec.col
        or spec.severity
        or spec.code
        or spec.message

    return has_info ~= nil
end

---@return terminal-diagnostics.Matcher
function matcher_generators.generate_simple_matcher(options)
    local pattern = options.pattern
    local last_match_pos
    ---@type terminal-diagnostics.Matcher
    ---@diagnostic disable-next-line: missing-fields
    local matcher = {}

    matcher.name = function()
        return options.name
    end

    matcher.kind = function()
        return options.kind
    end

    matcher.match = function(_options)
        local count = _options.count or 1
        local match

        if last_match_pos then
            match = utils.patterns.find_at_cursor(_options.buffer, pattern)
            last_match_pos = nil
        else
            match = utils.patterns.find(_options.buffer, pattern, count)
        end

        if not match then
            return nil, nil
        end

        return match, patterns.extract_from_match(pattern, match)
    end

    matcher.match_start = function(_options)
        local count = _options.count or 1
        local pos = utils.patterns.find(_options.buffer, pattern, count)

        if not pos then
            last_match_pos = nil
            return
        end

        last_match_pos = pos

        return pos
    end

    matcher.match_at_cursor = function(_options)
        local match = utils.patterns.find_at_cursor(_options.buffer, pattern)

        if not match then
            return nil, nil
        end

        return match, patterns.extract_from_match(pattern, match)
    end

    return matcher
end

---@param options terminal-diagnostics.HeaderMatcherOptions
---@return terminal-diagnostics.Matcher
function matcher_generators.generate_header_matcher(options)
    local header_pattern, error_line_pattern =
        options.header_pattern, options.error_line_pattern
    local last_match_pos
    local include_header = spec_has_info(options.header_pattern)
    ---@type terminal-diagnostics.Matcher
    ---@diagnostic disable-next-line: missing-fields
    local matcher = {}

    matcher.name = function()
        return options.name
    end

    matcher.kind = function()
        return options.kind
    end

    matcher.match = function(_options)
        local buffer = _options.buffer
        local count = _options.count or 1
        local match

        if last_match_pos then
            match = utils.patterns.find_at_cursor(buffer, error_line_pattern.regex)
            last_match_pos = nil
        else
            local on_header =
                utils.patterns.find_at_cursor(buffer, header_pattern.regex)

            if on_header then
                if include_header then
                    match = on_header
                else
                    match = utils.patterns.find(buffer, error_line_pattern, count)
                end
            else
                match = utils.patterns.find(buffer, error_line_pattern, count)
            end
        end

        if not match then
            return
        end

        return match, patterns.extract_from_match(error_line_pattern, match)
    end

    matcher.match_start = function(_options)
        local buffer = _options.buffer
        local count = _options.count or 1
        local header_pos = utils.patterns.find(buffer, header_pattern, count)
        local error_line_pos = utils.patterns.find(buffer, error_line_pattern, count)

        if include_header then
            if header_pos and error_line_pos then
                if header_pos.from.lnum < error_line_pos.from.lnum then
                    last_match_pos = header_pos
                else
                    last_match_pos = error_line_pos
                end
            elseif error_line_pos then
                last_match_pos = error_line_pos
            end
        else
            if error_line_pos then
                last_match_pos = error_line_pos
            else
                last_match_pos = nil
            end
        end

        return last_match_pos
    end

    matcher.match_at_cursor = function(_options)
        -- TODO: Match header and find next error_line_pattern
        local match =
            utils.patterns.find_at_cursor(_options.buffer, error_line_pattern)

        if not match then
            return nil, nil
        end

        return match, patterns.extract_from_match(error_line_pattern, match)
    end

    return matcher
end

function matcher_generators.generate_sectioned_matcher(pattern) end

return matcher_generators
