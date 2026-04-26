local matcher_generators = {}

local utils = require("terminal-diagnostics.utils")
local matchers = require("terminal-diagnostics.matchers")

-- TODO: Support multiple error formats for generators
-- TODO: Pass multiple error messages to generators to support e.g. clang/gcc
--       with both compile and linker errors
-- TODO: Match/parse any additional error context for visual selection and for creating diagnostics
-- TODO: Use "end_patterns" for delimiting additional error contexts

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

---@param options terminal-diagnostics.SimpleMatcherOptions
---@return terminal-diagnostics.Matcher
function matcher_generators.generate_simple_matcher(options)
    local last_match_pos

    ---@type terminal-diagnostics.Matcher
    local matcher = {
        specs = function()
            return options.specs
        end,
        match = function(_options)
            local count = _options.count or 1
            local match

            for _, spec in ipairs(options.specs) do
                if last_match_pos then
                    match = utils.patterns.find_at_cursor(_options.buffer, spec)

                    if match then
                        last_match_pos = nil

                        return spec, match
                    end
                else
                    match = utils.patterns.find(_options.buffer, spec, count)

                    if match then
                        return spec, match
                    end
                end
            end

            if not match then
                return
            end
        end,
        match_start = function(_options)
            local count = _options.count or 1
            local pos

            for _, spec in ipairs(options.specs) do
                pos = utils.patterns.find(_options.buffer, spec, count)
                last_match_pos = pos

                if pos then
                    break
                end
            end

            return pos
        end,
        match_at_cursor = function(_options)
            local match

            for _, spec in ipairs(options.specs) do
                match = utils.patterns.find_at_cursor(_options.buffer, spec)

                if match then
                    return spec, match
                end
            end
        end
    }

    return matcher
end

---@param options terminal-diagnostics.HeaderMatcherOptions
---@return terminal-diagnostics.Matcher
function matcher_generators.generate_header_matcher(options)
    local last_match_pos

    ---@type terminal-diagnostics.Matcher
    local matcher = {
        specs = function()
            return options.specs
        end,
        match = function(_options)
            local buffer = _options.buffer
            local count = _options.count or 1
            local match

            for _, spec in ipairs(options.specs) do
                local include_header = spec_has_info(spec.header_spec)
                local error_spec = spec.error_spec

                if last_match_pos then
                    match = utils.patterns.find_at_cursor(buffer, error_spec.pattern)

                    if match then
                        last_match_pos = nil

                        return match, matchers.extract_from_match(spec.error_spec, match)
                    end
                else
                    local on_header = utils.patterns.find_at_cursor(buffer, spec.header_spec.pattern)

                    if on_header then
                        if include_header then
                            match = on_header
                        else
                            match = utils.patterns.find(buffer, error_spec, count)
                        end
                    else
                        match = utils.patterns.find(buffer, error_spec, count)

                        if match then
                            return match, matchers.extract_from_match(spec.error_spec, match)
                        end
                    end
                end
            end
        end,
        match_start = function(_options)
            local buffer = _options.buffer
            local count = _options.count or 1

            for _, spec in ipairs(options.specs) do
                local error_spec = spec.error_spec
                local include_header = spec_has_info(spec.header_spec)
                local header_pos = utils.patterns.find(buffer, spec.header_spec, count)
                local error_line_pos = utils.patterns.find(buffer, error_spec, count)

                if include_header then
                    if header_pos and error_line_pos then
                        if header_pos.from.lnum < error_line_pos.from.lnum then
                            last_match_pos = header_pos
                            break
                        else
                            last_match_pos = error_line_pos
                            break
                        end
                    elseif error_line_pos then
                        last_match_pos = error_line_pos
                            break
                    end
                else
                    if error_line_pos then
                        last_match_pos = error_line_pos
                        break
                    else
                        last_match_pos = nil
                    end
                end
            end

            return last_match_pos
        end,
        match_at_cursor = function(_options)
            -- TODO: Match header and find next error_line_pattern
            for _, spec in ipairs(options.specs) do
                local match = utils.patterns.find_at_cursor(_options.buffer, spec.error_spec)

                if match then
                    return match, _options.extract and matchers.extract_from_match(spec.error_spec, match) or nil
                end
            end
        end
    }

    return matcher
end

-- function matcher_generators.generate_sectioned_matcher(pattern) end

return matcher_generators
