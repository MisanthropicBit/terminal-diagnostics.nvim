---@alias terminal-diagnostics.NotifyFunc fun(message: string, ...: any)

---@class terminal-diagnostics.notify
---@field debug terminal-diagnostics.NotifyFunc
---@field info  terminal-diagnostics.NotifyFunc
---@field warn  terminal-diagnostics.NotifyFunc
---@field error terminal-diagnostics.NotifyFunc
local notify = {}

-- local log = require("terminal-diagnostics.log")

local supported_levels = {
    debug = vim.log.levels.DEBUG,
    info = vim.log.levels.INFO,
    warn = vim.log.levels.WARN,
    error = vim.log.levels.ERROR,
}

---@param message string
---@param level integer
---@param ... any
local function _notify(message, level, ...)
    local args = { ... }

    -- Notification may be overridden by the user and call vimscript functions or
    -- functions that are not safe to call in async code
    if vim.in_fast_event() then
        vim.schedule(function()
            vim.notify(message:format(unpack(args)), level, { title = "terminal-diagnostics.nvim" })
        end)
    else
        vim.notify(message:format(unpack(args)), level, { title = "terminal-diagnostics.nvim" })
    end
end

notify.log = {}

for name, level in pairs(supported_levels) do
    ---@param message string
    ---@param ... any
    local notify_func = function(message, ...)
        _notify(message, level, ...)
    end

    notify[name] = notify_func

    -- notify.log[name] = function(message, ...)
    --     notify_func(message, ...)
    --     log[name](message, ...)
    -- end
end

return notify
