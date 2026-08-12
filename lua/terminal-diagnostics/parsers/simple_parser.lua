local Parser = require("terminal-diagnostics.parsers.parser")
local matchers = require("terminal-diagnostics.matchers")
local patterns = require("terminal-diagnostics.patterns")

---@class terminal-diagnostics.parser.SimpleMatcherParser : terminal-diagnostics.parser.Parser
---@field private command_spec terminal-diagnostics.CommandSpec
local SimpleParser = setmetatable({}, Parser)

SimpleParser.__index = SimpleParser

---@param command_spec terminal-diagnostics.CommandSpec?
---@return terminal-diagnostics.parser.SimpleMatcherParser
function SimpleParser.new(command_spec)
    -- TODO: Check matcher kind
    return setmetatable({ _command_spec = command_spec }, SimpleParser)
end

---@param lines string[]
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function SimpleParser:parse(lines, options)
    local results = {} ---@type terminal-diagnostics.parser.ParseResult[]
    local specs = self._command_spec:matcher():specs()
    local _options = options or {}
    local offset = _options.offset or 1
    local extract_match = _options.extract
    local count = 0
    local source = self._command_spec:name()
    local kind = self._command_spec:kind()
    local has_context = self:has_context()
    local idx = 1

    while idx <= #lines do
        for _, spec in ipairs(specs) do
            -- Skip specs that contain no information
            if not matchers.spec_has_info(spec) then
                goto continue
            end

            local match = patterns.find_at_line(lines, spec, idx)

            if not match then
                idx = idx + 1
                goto continue
            end

            -- TODO: Support for:
            -- 1. Additional error output between error lines
            -- 2. Additional error output after and between error lines
            -- 3. No additional error output

            local parse_result = Parser.create_parse_result({
                source = source,
                buffer = options.buffer,
                kind = kind,
                matches = { match },
            }, offset - 1)

            if extract_match then
                parse_result.values = self._command_spec:matcher():extract_values({ match })
            end

            table.insert(results, parse_result)

            if has_context then
                idx = idx + #spec.subpatterns
                local prev_idx = idx

                while self:is_context_line(lines[idx]) do
                    idx = idx + 1
                end

                if prev_idx < idx then
                    results[#results].context = Parser.create_parse_context(
                        lines,
                        offset - 1,
                        prev_idx,
                        idx - 1
                    )
                end
            else
                idx = idx + 1
            end

            count = count + 1

            if _options.count and count == _options.count then
                break
            end

            ::continue::
        end

        if options.count and count == options.count then
            break
        end
    end

    if options.count and count == options.count then
        return results
    end

    return results
end

return SimpleParser
