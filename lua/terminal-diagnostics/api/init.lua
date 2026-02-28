return setmetatable({}, {
    __index = function(_, key)
        vim.print(key)
        return require("terminal-diagnostics.api." .. key)
    end
})
