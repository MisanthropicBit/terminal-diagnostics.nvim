---@type terminal-diagnostics.TerminalRequestHandler
---@diagnostic disable-next-line: missing-fields
local handler = {}

local Cache = require("terminal-diagnostics.utils.cache")
local utils = require("terminal-diagnostics.utils")
local terminal = require("terminal-diagnostics.terminal")

-- TODO: Parse cmdline_url from MARK_COMMAND_START
-- TODO: Use vim.api.buf_attach for monitoring for scrollback clears. If the
-- range that got changed has a lower starting number than the last range then
-- the screen was probably cleared. Works for <c-l> and printf of the escape
-- sequence (test also with 'set scrollback=0'). Can we be sure that the screen
-- got cleared?

---@class terminal-diagnostics.TerminalBufferCacheEntry
---@field buffer       integer
---@field input_range  terminal-diagnostics.Range?
---@field output_range terminal-diagnostics.Range?
---@field command_line string[]?
---@field exit_code    integer?

local ESC = "\027"
local OSC_133 = ESC .. "]133;"
local MARK_PROMPT_START = OSC_133 .. "A"
local MARK_PROMPT_END = OSC_133 .. "B"
local MARK_COMMAND_START = OSC_133 .. "C"
local MARK_COMMAND_END = OSC_133 .. "D"
local CWD = ESC .. "]7;"

local autocmd_id

-- TODO: Probably doesn't work if multiple shells are used in the same session
local has_prompt_markers = false

-- If the shell emits command markers then use those instead of the prompt markers
local has_command_markers = false

local has_cmdline_url_extension = false

---@param marker string
---@return string[]?
local function parse_command_start_marker(marker)
    local tail = vim.iter(vim.gsplit(marker, ";", { plain = true })):skip(2)

    if not tail:peek() then
        return
    end

    local rest = tail:join("")

    if vim.startswith(rest, "cmdline_url=") then
        local encoded_command_line = table.concat(
            vim.iter(vim.gsplit(rest, "=", { plain = true })):skip(1):totable(),
            ""
        )

        return vim.split(
            utils.url.decode(encoded_command_line),
            "\r?\n",
            { plain = false }
        )
    elseif vim.startswith(rest, "cmdline=") then
        -- TODO: Parse %q-encoding
    else
        -- Unrecognised format
        return
    end
end

---@param marker string
---@return integer?
local function parse_command_end_marker(marker)
    local tail = vim.iter(vim.gsplit(marker, ";", { plain = true })):skip(2):totable()

    if not tail then
        return
    end

    return tonumber(table.concat(tail, ""))
end

---@param sequence string
---@return string?
local function parse_cwd_sequence(sequence)
    local tail = vim.iter(vim.gsplit(sequence, ";", { plain = true })):skip(2)

    if not tail:peek() then
        return
    end

    -- Skip 'file://' at start and '\027\\' at end
    local rest = tail:join(""):sub(8):sub(1, -3)

    return rest
end

--- Check if an escape sequence matches a prompt or command marker
---@param sequence string
---@param marker   string
local function matches_marker(sequence, marker)
    return sequence:match("^" .. marker) ~= nil
end

---@type terminal-diagnostics.Cache
local terminal_buffer_cache = Cache.new(nil, {
    default = function()
        return {
            buffer = -1,
            input_pos = { value = nil, start = nil, end_ = nil },
            output_pos = { start = nil, end_ = nil },
        }
    end,
})

---@param buffer integer
---@param region terminal-diagnostics.Range
---@return string[]
local function get_buf_text_region(buffer, region)
    if not region.from or not region.to then
        return {}
    end

    local start_lnum, start_col = region.from.lnum, region.from.col
    local end_lnum, end_col = region.to.lnum, region.to.col

    return vim.api.nvim_buf_get_text(buffer, start_lnum, start_col, end_lnum, end_col, {})
end

---@param buffer integer
---@param entry terminal-diagnostics.TerminalBufferCacheEntry
---@return terminal-diagnostics.TerminalRequestOutputEvent?
local function create_output_event(buffer, entry)
    local output = get_buf_text_region(buffer, entry.output_range)

    -- If there is no output, there are no diagnostics to generate
    if #output == 0 then
        return
    end

    local input = entry.command_line or get_buf_text_region(buffer, entry.input_range)

    return {
        buffer = buffer,
        type = terminal.TerminalEventType.OutputEvent,
        input = input,
        input_range = entry.input_range,
        output = output,
        output_range = entry.output_range,
        exit_code = entry.exit_code,
        has_ansi = false,
    }
end

function handler.start(callback)
    -- TODO: Use vim.startswith since sequences can contain more than just the
    -- sequence itself

    autocmd_id = vim.api.nvim_create_autocmd("TermRequest", {
        callback = function(event)
            local buffer = event.buf
            local sequence = event.data.sequence
            local lnum, col = unpack(event.data.cursor)

            if matches_marker(sequence, MARK_PROMPT_START) then
                has_prompt_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                -- Only dispatch if we have output data
                if entry.output_range.from then
                    local term_request_event = create_output_event(buffer, entry)

                    if term_request_event then
                        callback(term_request_event)
                        terminal_buffer_cache:remove(buffer)
                    end
                end
            elseif matches_marker(sequence, MARK_PROMPT_END) then
                has_prompt_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                -- Save the prompt end as the start of command output. If the terminal
                -- emits command markers, this will be overwritten by the command start
                -- marker
                if not has_command_markers then
                    entry.output_range.from = { lnum = lnum + 1, col = col }
                end

                -- Save the prompt end as the start of user input
                entry.input_range.from = { lnum = lnum, col = col + 1 }
                -- terminal_buffer_cache:set(buffer, entry)
            elseif matches_marker(sequence, MARK_COMMAND_START) then
                has_command_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                entry.output_range.from = { lnum = lnum, col = col }
                -- terminal_buffer_cache:set(buffer, entry)

                local command_line = parse_command_start_marker(sequence)

                if command_line then
                    has_cmdline_url_extension = true
                    entry.command_line = command_line
                end

                -- If we have prompt markers, save the start of the command
                -- output as the end of user ipnut
                if has_prompt_markers then
                    entry.input_range.to = { lnum = lnum, col = col - 1 }
                end
            elseif matches_marker(sequence, MARK_COMMAND_END) then
                has_command_markers = true

                ---@type terminal-diagnostics.TerminalBufferCacheEntry
                local entry = terminal_buffer_cache:get(buffer)

                entry.exit_code = parse_command_end_marker(sequence)
                entry.output_range.to = { lnum = lnum, col = col }
            elseif matches_marker(sequence, CWD) then
                local directory = parse_cwd_sequence(sequence)

                if directory then
                    callback({
                        buffer = buffer,
                        type = terminal.TerminalEventType.DirectoryEvent,
                        directory = directory
                    })
                end
            end
        end,
    })
end

function handler.stop()
    if not autocmd_id then
        error("Cannot stop terminal request handler as it was not started")
    end

    vim.api.nvim_del_autocmd(autocmd_id)
end

return handler
