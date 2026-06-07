-- TODO: ParseOptions.context is not a great name

---@class terminal-diagnostics.ParseOptions
---@field buffer  integer? The buffer that lines originating from if any
---@field offset  integer?
---@field context terminal-diagnostics.ParseContext?
---@field count   integer?

---@class terminal-diagnostics.parser.Parser
---@field _command_spec terminal-diagnostics.CommandSpec
local Parser = {}

Parser.__index = Parser

---@return terminal-diagnostics.parser.Parser
function Parser.new()
    return setmetatable({}, Parser)
end

---@param command_spec terminal-diagnostics.CommandSpec
function Parser:set_command_spec(command_spec)
    self._command_spec = command_spec
end

---@param lines string[]
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
---@diagnostic disable-next-line: unused-local
function Parser:parse(lines, options)
    error("Not implemented")
end

---@param buffer integer
---@param options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function Parser:parse_buffer(buffer, options)
    local offset = options and options.offset or 0
    local last_lnum = vim.api.nvim_buf_line_count(buffer) - 1
    local lines = vim.api.nvim_buf_get_lines(buffer, offset, last_lnum, true)

    return self:parse(lines, options)
end

---@param lines string[]
---@param offset integer
---@param start integer
---@param end_ integer
---@return terminal-diagnostics.parser.ParseResultContext?
function Parser.create_parse_context(lines, offset, start, end_)
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

---@return terminal-diagnostics.parser.ParseResult
function Parser.create_parse_result(values)
    local matches = values.matches

    return {
        source = values.source,
        buffer = values.buffer,
        kind = values.kind,
        range = {
            start = {
                lnum = matches[1].from.lnum,
                col = matches[#matches].from.col,
            },
            end_ = {
                lnum = matches[1].to.lnum,
                col = matches[#matches].to.col,
            },
        },
        matches = matches,
    }
end

return Parser
