local terminal_diagnostics = {}

local version = "0.1.0"

---@return string
function terminal_diagnostics.version()
    return version
end

---@param config terminal-diagnostics.Config?
function terminal_diagnostics.setup(config)
    local _config = config
        or require("terminal-diagnostics.config")._default_config()

    require("terminal-diagnostics.config").setup(_config)
    require("terminal-diagnostics.diagnostics").setup({}) -- _config.diagnostics)
    require("terminal-diagnostics.highlights").setup()

    local handler = require(
        "terminal-diagnostics.terminal.output-handlers.osc_133_request_handler"
    )

    handler.start(function(event)
        vim.print("processing")
        local SequentialOutputProcessor =
            require("terminal-diagnostics.output_processors.sequential")
        local processor = SequentialOutputProcessor.new()

        processor.process(event, { quickfix = true })
    end)
end

terminal_diagnostics.api = require("terminal-diagnostics.api")

return terminal_diagnostics
