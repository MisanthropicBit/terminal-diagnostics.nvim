-- TODO: ParseOptions.context is not a great name

---@class terminal-diagnostics.ParseOptions
---@field buffer  integer? The buffer that lines originating from if any
---@field offset  integer?
---@field extract boolean?
---@field count   integer?

---@class terminal-diagnostics.parser.Parser
---@field _command_spec   terminal-diagnostics.CommandSpec
---@field is_context_line (fun(self: terminal-diagnostics.parser.Parser, line: string): boolean)?
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
    if not vim.api.nvim_buf_is_valid(buffer) then
        -- TODO: How to handle?
        return {}
    end

    local offset = options and options.offset or 1
    local last_lnum = vim.api.nvim_buf_line_count(buffer)
    local lines = vim.api.nvim_buf_get_lines(buffer, offset - 1, last_lnum, true)

    return self:parse(lines, vim.tbl_extend("force", options, { buffer = buffer }))
end

---@param lines string[]
---@param offset integer
---@param start integer
---@param end_ integer
---@return terminal-diagnostics.parser.ParseResultContext?
function Parser.create_parse_context(lines, offset, start, end_)
    local context_lines = vim.list_slice(lines, start, end_)

    if #context_lines == 0 then
        return nil
    end

    return {
        lines = context_lines,
        range = {
            start = {
                lnum = start + offset - 1,
                col = 0,
            },
            end_ = {
                lnum = end_ + offset - 1,
                col = #lines[end_],
            },
        },
    }
end

---@param values unknown
---@param offset integer?
---@return terminal-diagnostics.parser.ParseResult
function Parser.create_parse_result(values, offset)
    local matches = values.matches
    local _offset = offset or 0

    return {
        source = values.source,
        buffer = values.buffer,
        kind = values.kind,
        range = {
            start = {
                lnum = matches[1].range.from.lnum + _offset,
                col = matches[#matches].range.from.col,
            },
            end_ = {
                lnum = matches[1].range.to.lnum + _offset,
                col = matches[#matches].range.to.col,
            },
        },
        matches = matches,
    }
end

---@return boolean
function Parser:has_context()
    ---@diagnostic disable-next-line: undefined-field
    return self.is_context_line ~= nil
end

---@param mixin table<string, function>
function Parser:extend(mixin)
    for method_name, impl in pairs(mixin) do
        self[method_name] = impl
    end
end

return Parser
