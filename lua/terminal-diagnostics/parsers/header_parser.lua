local Parser = require("terminal-diagnostics.parsers.parser")
local patterns = require("terminal-diagnostics.patterns")
local matchers = require("terminal-diagnostics.matchers")

---@class terminal-diagnostics.HeaderParserOptions : terminal-diagnostics.ParserOptions

---@class terminal-diagnostics.HeaderParseOptions : terminal-diagnostics.ParseOptions
---@field last_header_match terminal-diagnostics.Match? An inital header match usually used with a parse offset

---@class terminal-diagnostics.parser.HeaderParser : terminal-diagnostics.parser.Parser
---@field private command_spec terminal-diagnostics.CommandSpec
local HeaderParser = setmetatable({}, Parser)

HeaderParser.__index = HeaderParser

---@param options terminal-diagnostics.HeaderParserOptions?
---@return terminal-diagnostics.parser.HeaderParser
function HeaderParser.new(options)
    local _options = options or {}

    return setmetatable({
        _command_spec = _options.command_spec,
        _has_context = _options.has_context,
    }, HeaderParser)
end

---@return terminal-diagnostics.ParserKind
function HeaderParser:kind()
    return Parser.ParserKind.Header
end

---@param lines string[]
---@param options terminal-diagnostics.HeaderParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function HeaderParser:parse(lines, options)
    if not self._command_spec then
        error("No command spec was set for parser")
    end

    local _options = options or {}
    local results = {} ---@type terminal-diagnostics.parser.ParseResult[]
    local specs = self._command_spec:matcher():specs()
    local header_spec = specs[1]
    local error_spec = specs[2]
    local offset = _options.offset or 1
    local extract_match = _options.extract
    local count = 0
    local has_context = self._command_spec:parser():has_context()
    local last_header_match = _options.last_header_match ---@type terminal-diagnostics.Match?
    local idx = 1

    -- TODO: Refactor
    while idx <= #lines do
        local header_match = patterns.find_at_line(lines, header_spec, idx)

        -- Check if the current line is a header
        if header_match then
            last_header_match = header_match

            local parse_result = Parser.create_parse_result({
                command_spec = self._command_spec,
                buffer = options.buffer,
                matches = { last_header_match },
            }, offset - 1)

            if extract_match and matchers.spec_has_info(header_spec) then
                parse_result.values = self._command_spec:matcher():extract_values({ last_header_match })
            end

            table.insert(results, parse_result)

            if has_context then
                local new_idx, context = self:parse_context_lines(header_spec, idx, offset, lines)
                idx = new_idx
                results[#results].context = context
                count = count + 1

                if options.count and count == options.count then
                    break
                end
            else
                idx = idx + 1
                goto continue
            end
        end

        if last_header_match then
            local error_match = patterns.find_at_line(lines, error_spec, idx)

            if not error_match then
                idx = idx + 1
                goto continue
            end

            local parse_result = Parser.create_parse_result({
                command_spec = self._command_spec,
                buffer = options.buffer,
                matches = { error_match },
            }, offset - 1)

            if extract_match then
                local matches = { error_match }

                if last_header_match then
                    table.insert(matches, 1, last_header_match)
                end

                parse_result.values = self._command_spec:matcher():extract_values(matches)
            end

            table.insert(results, parse_result)

            if has_context then
                local new_idx, context = self:parse_context_lines(error_spec, idx, offset, lines)
                idx = new_idx
                results[#results].context = context
            else
                idx = idx + 1
            end

            count = count + 1

            if options.count and count == options.count then
                break
            end
        else
            idx = idx + 1
        end

        ::continue::
    end

    return results
end

---@param spec terminal-diagnostics.MatchSpec
---@param idx integer
---@param offset integer
---@param lines string[]
---@return integer
---@return (terminal-diagnostics.parser.ParseResultContext)?
function HeaderParser:parse_context_lines(spec, idx, offset, lines)
    local _idx = idx + #spec.subpatterns
    local prev_idx = _idx

    while self:is_context_line(lines[_idx], spec) and _idx <= #lines do
        _idx = _idx + 1
    end

    if prev_idx < _idx then
        return _idx, Parser.create_parse_context(
            lines,
            offset - 1,
            prev_idx,
            _idx - 1
        )
    else
        return _idx, nil
    end
end

return HeaderParser
