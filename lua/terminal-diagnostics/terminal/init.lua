local terminal = {}

---@class terminal-diagnostics.BaseTerminalRequestEvent
---@field buffer integer

---@class terminal-diagnostics.TerminalRequestOutputEvent : terminal-diagnostics.BaseTerminalRequestEvent
---@field type         "output_event"
---@field input        string[]? Input from terminal mode that resulted in the output
---@field input_range  terminal-diagnostics.Range?
---@field output       string[]  The output of a command in the terminal
---@field output_range terminal-diagnostics.Range?
---@field exit_code    integer?
---@field has_ansi     boolean

---@class terminal-diagnostics.TerminalRequestDirectoryEvent : terminal-diagnostics.BaseTerminalRequestEvent
---@field type      "directory_event"
---@field directory string

---@alias terminal-diagnostics.TerminalRequestEvent
---| terminal-diagnostics.TerminalRequestOutputEvent
---| terminal-diagnostics.TerminalRequestDirectoryEvent

---@alias terminal-diagnostics.OutputHandlerCallback fun(event: terminal-diagnostics.TerminalRequestEvent)

---@class terminal-diagnostics.TerminalRequestHandler
---@field start fun(callback: terminal-diagnostics.OutputHandlerCallback)
---@field stop fun()

---@enum terminal-diagnostics.TerminalEventType
terminal.TerminalEventType = {
    OutputEvent = "output_event",
    DirectoryEvent = "directory_event",
}

return terminal
