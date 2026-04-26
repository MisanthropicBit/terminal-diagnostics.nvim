return setmetatable({}, {
    __call = function(_, module)
        if type(module) ~= "string" then
            error(("Expected module name, got %s"):format(vim.inspect(module)))
        end

        return setmetatable({}, {
            __index = function(_, key)
                return require(module)[key]
            end,
        })
    end,
})

