local Enum = setmetatable({}, {
    __index = function(_, key)
        error(("Unknown constant value '%s'"):format(key))
    end,
    __newindex = function(_, _)
        error("Cannot modify enum")
    end
})

Enum.__index = Enum

function Enum.new(values)
    local enum = {}

    for _, value in ipairs(values) do
        enum[value] = value
    end

    enum.values = values

    return setmetatable(enum, Enum)
end

function Enum:contains(value)
    for key in pairs(self) do
        if key == value then
            return true
        end
    end

    return false
end

return Enum
