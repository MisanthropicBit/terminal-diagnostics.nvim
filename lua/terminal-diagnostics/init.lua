local terminal_diagnostics = {}

---@param event terminal-diagnostics.TerminalOutputEvent
local function terminal_event_handler(event)
    vim.print(vim.inspect(event.output))

    -- 1. Loop through all supported patterns and see if we can find a match
    --    (use an lru cache for most recent matches)

    -- 2. If there is a match, find all matches

    -- 3. Convert all matches to diagnostics

    -- 4. Set/update diagnostics for buffer

    -- 5. If no ansi and config option is enabled, set extmarks

    -- 6. Update information such as "diagnostics for last command"
end

function terminal_diagnostics.setup()
    -- local output_handler = require("terminal_diagnostics.terminal.output_handlers.osc_133_request_handler")
    --
    -- output_handler.start(terminal_event_handler)
end

return terminal_diagnostics
