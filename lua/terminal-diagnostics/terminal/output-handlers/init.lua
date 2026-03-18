---@class terminal-diagnostics.TerminalOutputEvent
---@field buffer     integer
---@field input      string[]? Input from terminal mode that resulted in the output
---@field input_pos  terminal-diagnostics.Region?
---@field output     string[]  The output of a command in the terminal
---@field output_pos terminal-diagnostics.Region?
---@field exit_code  integer?
---@field has_ansi   boolean

---@alias terminal-diagnostics.OutputHandlerCallback fun(event: terminal-diagnostics.TerminalOutputEvent)

---@class terminal-diagnostics.OutputHandler
---@field start fun(callback: terminal-diagnostics.OutputHandlerCallback)
---@field stop fun()
