---@class terminal-diagnostics.utils.url
---@field encode fun(value: string): string

---@class terminal-diagnostics.utils
---@field url terminal-diagnostics.utils.url

return setmetatable({}, {
    ---@type terminal-diagnostics.utils
    __index = function(_, key)
        return require("terminal-diagnostics.utils." .. key)
    end
})
