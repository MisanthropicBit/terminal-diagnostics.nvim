---@type terminal-diagnostics.OutputHandler
---@diagnostic disable-next-line: missing-fields
local handler = {}

local Cache = require("terminal-diagnostics.utils.cache")

-- TODO: Parse cmdline_url from MARK_COMMAND_START

---@class terminal-diagnostics.Position
---@field lnum integer
---@field col  integer

---@class terminal-diagnostics.Region
---@field start terminal-diagnostics.Position
---@field end_  terminal-diagnostics.Position

---@class terminal-diagnostics.TerminalBufferCacheEntry
---@field buffer integer
---@field input  terminal-diagnostics.Region?
---@field output terminal-diagnostics.Region?

local OSC_133 = "^\027]133;"
local MARK_PROMPT_START = OSC_133 .. "A"
local MARK_PROMPT_END = OSC_133 .. "B"
local MARK_COMMAND_START = OSC_133 .. "C"
local MARK_COMMAND_END = OSC_133 .. "D"

local autocmd_handler_id

local has_prompt_markers = false

-- If the shell emits command markers then use those instead of the prompt markers
local has_command_markers = false

local has_cmdline_url_extension = false

---@param marker string
---@return string?
local function parse_command_start_marker(marker)
    local tail = vim.iter(vim.gsplit(marker, ";", { plain = true })):skip(2):totable()

    if not tail then
        return
    end

    local rest = table.concat(tail, "")

    if vim.startswith(rest, "cmdline_url") then
        -- TODO: Parse utf-8 url %-escaped text
    elseif vim.startswith(rest, "cmdline") then
        -- TODO: Parse %q-encoding
    else
        -- Unrecognised format
        return
    end
end

---@type terminal-diagnostics.Cache
local terminal_buffer_cache = Cache.new(nil, {
    default = function()
        return {
            buffer = -1,
            input = { value = nil, start = nil, end_ = nil },
            output = { start = nil, end_ = nil },
        }
    end,
})

---@param buffer integer
---@param region terminal-diagnostics.Region
---@return string[]
local function get_buf_text_region(buffer, region)
    local start_lnum, start_col = region.start.lnum, region.start.col
    local end_lnum, end_col = region.end_.lnum, region.end_.col

    return vim.api.nvim_buf_get_text(buffer, start_lnum, start_col, end_lnum, end_col, {})
end

--- Dispatch a terminal input/output event
---@param entry    terminal-diagnostics.TerminalBufferCacheEntry
---@param callback terminal-diagnostics.OutputHandlerCallback
local function dispatch_event(entry, callback)
    local output = get_buf_text_region(entry.buffer, entry.output)

    -- If there is no output, there are no diagnostics to generate
    if #output == 0 then
        return
    end

    local has_ansi = false

    for _, line in ipairs(output) do
        if line:match("TODO: ANSI PATTERN") then
            has_ansi = true
            break
        end
    end

    local input = get_buf_text_region(entry.buffer, entry.input)

    callback({ buffer = entry.buffer, input = input, output = output, has_ansi = has_ansi })
end

function handler.start(callback)
    -- TODO: Use vim.startswith since sequences can contain more than just the
    -- sequence itself

    autocmd_handler_id = vim.api.nvim_create_autocmd("TermRequest", {
        callback = function(event)
            local buffer = event.buf
            local sequence = event.data.sequence
            local lnum, col = unpack(event.data.cursor)

            if sequence == MARK_PROMPT_START and not has_command_markers then
                has_prompt_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                -- Only dispatch if we have output data
                if entry.output.start then
                    dispatch_event(entry, callback)
                    terminal_buffer_cache:remove(buffer)
                end
            elseif sequence == MARK_PROMPT_END then
                has_prompt_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                -- Save the prompt end as the start of command output. If the terminal
                -- emits command markers, this will be overwritten by the command start
                -- marker
                if not has_command_markers then
                    entry.output.start = { lnum = lnum + 1, col = col }
                end

                -- Save the prompt end as the start of user input
                entry.input.start = { lnum = lnum, col = col + 1 }
            elseif sequence == MARK_COMMAND_START then
                has_command_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                entry.output.start = { lnum = lnum, col = col }

                local cmdline = parse_command_start_marker(sequence)

                if cmdline then
                    has_cmdline_url_extension = true
                    entry.input.value = cmdline
                end

                -- If we have prompt markers, save the start of the command
                -- output as the end of user ipnut
                if has_prompt_markers then
                    entry.input.end_ = { lnum = lnum, col = col - 1 }
                end
            elseif sequence == MARK_COMMAND_END then
                has_command_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)
                entry.output.end_ = { lnum = lnum, col = col }

                dispatch_event(entry, callback)

                terminal_buffer_cache:remove(buffer)
            end
        end,
    })
end

function handler.stop()
    if not autocmd_handler_id then
        return
    end

    vim.api.nvim_del_autocmd(autocmd_handler_id)
end

return handler
