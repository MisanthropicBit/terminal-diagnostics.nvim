local terminal_diagnostics = {}

local version = "0.1.0"

---@return string
function terminal_diagnostics.version()
    return version
end

---@param user_config terminal-diagnostics.Config?
function terminal_diagnostics.setup(user_config)
    local config = require("terminal-diagnostics.config")
    config.setup(user_config)

    local diagnostics = require("terminal-diagnostics.diagnostics")
    diagnostics.setup({}) -- _config.diagnostics)

    require("terminal-diagnostics.highlights").setup()

    if config.terminal.enabled then
        local terminal = require("terminal-diagnostics.terminal")
        local handler = require("terminal-diagnostics.terminal.terminal_request_handler")

        handler.start(function(event)
            if event.type == terminal.TerminalEventType.OutputEvent then
                diagnostics.create_for_event(
                    event,
                    config.terminal.diagnostics.create_options
                )
            end
        end)
    end
end

---@param options terminal-diagnostics.JumpOptions?
---@return terminal-diagnostics.ApiResult?
function terminal_diagnostics.jump(options)
    return require("terminal-diagnostics.api.jump").jump(options)
end

---@param buffer integer
---@return terminal-diagnostics.ApiResult?
function terminal_diagnostics.find_at_cursor(buffer)
    return require("terminal-diagnostics.api.cursor").find_at_cursor(buffer)
end

---@param options terminal-diagnostics.OpenOptions
function terminal_diagnostics.open(options)
    require("terminal-diagnostics.api.open").open(options)
end

---@param options terminal-diagnostics.SelectOptions?
function terminal_diagnostics.select(options)
    require("terminal-diagnostics.api.select").select(options)
end

return terminal_diagnostics
