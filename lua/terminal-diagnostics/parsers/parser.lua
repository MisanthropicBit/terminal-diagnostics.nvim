---@class terminal-diagnostics.ParseOptions
---@field offset  integer?
---@field context terminal-diagnostics.ParseContext?
---@field count   integer?

---@class terminal-diagnostics.parser.Parser
local Parser = {}

Parser.__index = Parser

---@return terminal-diagnostics.parser.Parser
function Parser.new()
    return setmetatable({}, Parser)
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

return Parser
