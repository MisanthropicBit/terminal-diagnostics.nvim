local Parser = require("terminal-diagnostics.parsers.parser")
local matchers = require("terminal-diagnostics.matchers")
local utils = require("terminal-diagnostics.utils")

---@param lines string[]
---@param offset integer
---@param start integer
---@param end_ integer
---@return terminal-diagnostics.parser.ParseResultContext?
local function create_parse_context(lines, offset, start, end_)
    local context_lines = vim.list_slice(lines, start, end_ - 1)

    if #context_lines == 0 then
        return nil
    end

    return {
        lines = context_lines,
        range = {
            start = {
                lnum = offset + start - 1,
                col = 1,
            },
            end_ = {
                lnum = offset + end_ - 2,
                col = 1, -- TODO: Should be end column of lnum
            },
        },
    }
end

---@class terminal-diagnostics.parser.SimpleMatcherParser : terminal-diagnostics.parser.Parser
---@field private command_spec terminal-diagnostics.CommandSpec
local SimpleParser = setmetatable({}, Parser)

SimpleParser.__index = SimpleParser

---@param command_spec terminal-diagnostics.CommandSpec
---@return terminal-diagnostics.parser.SimpleMatcherParser
function SimpleParser.new(command_spec)
    -- TODO: Check matcher kind
    return setmetatable({ command_spec = command_spec }, SimpleParser)
end

---@param lines string[]
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function SimpleParser:parse(lines, options)
    local results = {} ---@type terminal-diagnostics.parser.ParseResult[]
    local start_marker ---@type integer?
    local specs = self.command_spec:matcher():specs()
    local offset = options and options.offset or 0
    local extract_match = false
    local count = 0
    local source = self.command_spec:name()
    local kind = self.command_spec:kind()

    if options.context then
        -- TODO: Should this be handled here or in the processors?

        -- Only extract and resolve matches (which may take some time)
        -- if we are adding the results to some kind of list
        if
            options.context.locationlist
            or options.context.quickfix
            or options.context.trouble
        then
            extract_match = true
        end
    end

    for idx, line in ipairs(lines) do
        for _, spec in ipairs(specs) do
            -- Skip specs that contain no information
            if not matchers.spec_has_info(spec) then
                goto continue
            end

            local lnum = idx + offset - 1
            local match = utils.patterns.find_in_line(line, spec, lnum)

            if not match then
                goto continue
            end

            -- TODO: Support for:
            -- 1. Additional error output between error lines
            -- 2. Additional error output after and between error lines
            -- 3. No additional error output

            if start_marker then
                results[#results].context = create_parse_context(
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

            ---@type terminal-diagnostics.parser.ParseResult
            local parse_result = {
                source = source,
                kind = kind,
                range = {
                    start = { lnum = lnum, col = match.from.col },
                    end_ = { lnum = lnum, col = match.to.col },
                },
                match = match,
            }

            if extract_match then
                parse_result.values = matchers.extract_from_match(spec, match)
            end

            table.insert(results, parse_result)

            -- Start the match for intermediary error output after the actual error line
            start_marker = idx + 1

            ::continue::
        end

        if options.count and count == options.count then
            break
        end
    end

    if options.count and count == options.count then
        return results
    end

    -- Parse any remaining lines that are not delimited by an end pattern
    if start_marker and start_marker < #lines then
        -- local context_lines = vim.list_slice(lines, start_marker, #lines)
        -- local is_empty = vim.iter(context_lines):all(function(line)
        --     return vim.fn.trim(line) == ""
        -- end)
        --
        -- if not is_empty then
            results[#results].context = create_parse_context(
                lines,
                offset,
                start_marker,
                #lines
            )
        -- end
    end

    return results
end

---@param buffer integer
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function SimpleParser:parse_buffer(buffer, options)
    if not vim.api.nvim_buf_is_valid(buffer) then
        -- TODO: How to handle?
        return {}
    end

    local offset = options and options.offset or 1
    local last_lnum = vim.api.nvim_buf_line_count(buffer)
    local lines = vim.api.nvim_buf_get_lines(buffer, offset - 1, last_lnum, true)

    return self:parse(lines, options)
end

return SimpleParser
