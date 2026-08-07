local Parser = require("terminal-diagnostics.parsers.parser")
local patterns = require("terminal-diagnostics.patterns")

---@class terminal-diagnostics.parser.HeaderMatcherParser : terminal-diagnostics.parser.Parser
---@field private command_spec terminal-diagnostics.CommandSpec
local HeaderParser = setmetatable({}, Parser)

HeaderParser.__index = HeaderParser

---@param command_spec terminal-diagnostics.CommandSpec?
---@return terminal-diagnostics.parser.HeaderMatcherParser
function HeaderParser.new(command_spec)
    return setmetatable({ _command_spec = command_spec }, HeaderParser)
end

---@param lines string[]
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function HeaderParser:parse(lines, options)
    if not self._command_spec then
        error("No command spec was set for parser")
    end

    local results = {} ---@type terminal-diagnostics.parser.ParseResult[]
    local specs = self._command_spec:matcher():specs()
    local header_spec = specs[1]
    local error_spec = specs[2]
    local offset = options and options.offset or 1
    local extract_match = options.extract
    local count = 0
    local has_context = self._command_spec:parser():has_context()
    local last_header_match
    local idx = 1

    while idx <= #lines do
        local lnum = idx + offset - 1

        if last_header_match then
            local error_match = patterns.find_at_line(lines, error_spec, lnum)

            if not error_match then
                idx = idx + 1
                goto continue
            end

            local parse_result = Parser.create_parse_result({
                command_spec = self._command_spec,
                buffer = options.buffer,
                matches = { error_match }, -- TODO: Do we need last_header_match here?
            }, offset - 1)

            if extract_match then
                parse_result.values = self._command_spec:matcher():extract_values({
                    last_header_match,
                    error_match,
                })
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
            last_header_match = patterns.find_at_line(lines, header_spec, lnum)

            if not last_header_match then
                idx = idx + 1
                goto continue
            end

            local parse_result = Parser.create_parse_result({
                command_spec = self._command_spec,
                buffer = options.buffer,
                matches = { last_header_match },
            }, offset - 1)

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
            end
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
