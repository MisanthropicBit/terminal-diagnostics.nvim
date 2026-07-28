local terminal_diagnostics = {}

local version = "0.1.0"

---@type terminal-diagnostics.OutputProcessor
local processor

---@return string
function terminal_diagnostics.version()
    return version
end

---@param user_config terminal-diagnostics.Config?
function terminal_diagnostics.setup(user_config)
    local config = require("terminal-diagnostics.config")
    config.setup(user_config)

    require("terminal-diagnostics.diagnostics").setup({}) -- _config.diagnostics)
    require("terminal-diagnostics.highlights").setup()

    if config.terminal_handler then
        local handler = require(
            "terminal-diagnostics.terminal.output-handlers.osc_133_request_handler"
        )

        if not processor then
            -- TODO: config.parallel
            local SequentialOutputProcessor =
                require("terminal-diagnostics.output_processors.sequential")

            processor = SequentialOutputProcessor.new()
            processor:start()

            if not processor:running() then
                require("terminal-diagnostics.notify").log.error("Failed to start output processor")
            else
                vim.api.nvim_create_autocmd("VimLeavePre", {
                    callback = function()
                        processor:stop()
                    end
                })

                handler.start(function(event)
                    processor:process(event, { quickfix = true, terminal_diagnostics = true })
                end)
            end
        end
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
