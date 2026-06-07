local Parser = require("terminal-diagnostics.parsers.parser")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.parser.HeaderMatcherParser : terminal-diagnostics.parser.Parser
---@field private command_spec terminal-diagnostics.CommandSpec
local HeaderParser = setmetatable({}, Parser)

HeaderParser.__index = HeaderParser

---@param command_spec terminal-diagnostics.CommandSpec
---@return terminal-diagnostics.parser.HeaderMatcherParser
function HeaderParser.new(command_spec)
    -- TODO: Check matcher kind
    return setmetatable({ _command_spec = command_spec }, HeaderParser)
end

---@param lines string[]
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function HeaderParser:parse(lines, options)
    local results = {} ---@type terminal-diagnostics.parser.ParseResult[]
    local start_marker ---@type integer?
    local specs = self._command_spec:matcher():specs()
    local offset = options and options.offset or 0
    local extract_match = false
    local count = 0
    local source = self._command_spec:name()
    local kind = self._command_spec:kind()
    local has_context = self._command_spec:has_context()
    local last_header_match
    local header_spec = specs[1]
    local error_spec = specs[2]

    for idx, _ in ipairs(lines) do
        local lnum = idx + offset - 1

        if last_header_match then
            local error_match = utils.patterns.find_at_line(lines, error_spec, lnum)

            if not error_match then
                goto continue
            end

            if has_context and start_marker then
                results[#results].context = Parser.create_parse_context(
                    lines,
                    offset,
                    start_marker,
                    idx
                )

                count = count + 1

                if options.count and count == options.count then
                    break
                end
            end

            local parse_result = Parser.create_parse_result({
                source = source,
                buffer = options.buffer,
                kind = kind,
                matches = { error_match }, -- TODO: Do we need last_header_match here?
            })

            if extract_match then
                parse_result.values = self._command_spec:matcher():extract_values({
                    { spec = header_spec, match = last_header_match },
                    { spec = error_spec, match = error_match },
                })
            end

            table.insert(results, parse_result)

            -- Start the match for intermediary error output after the actual error line
            start_marker = idx + 1
        else
            last_header_match = utils.patterns.find_at_line(lines, header_spec, lnum)
        end

        :: continue ::
    end

    return results
end

---@param buffer integer
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function HeaderParser:parse_buffer(buffer, options)
    if not vim.api.nvim_buf_is_valid(buffer) then
        -- TODO: How to handle?
        return {}
    end

    local offset = options and options.offset or 1
    local last_lnum = vim.api.nvim_buf_line_count(buffer)
    local lines = vim.api.nvim_buf_get_lines(buffer, offset - 1, last_lnum, true)

    return self:parse(lines, options)
end

return HeaderParser
