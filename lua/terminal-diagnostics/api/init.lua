return setmetatable({}, {
    __index = function(_, key)
        return require("terminal-diagnostics.api." .. key)
    end
})
