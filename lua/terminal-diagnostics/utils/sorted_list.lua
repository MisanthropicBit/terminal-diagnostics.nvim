---@class terminal-diagnostics.SortedList
---@field _values   unknown[]
---@field _key_func fun(value1: unknown, value2: unknown): -1 | 0 | 1
local SortedList = {}

SortedList.__index = SortedList

local function default_key_func(value)
    return value
end

--- A binary search implementation accounting for 1-based indexing
---@generic T
---@param value    T
---@param values   T[]
---@param key_func fun(value1: T, value2: T): -1 | 0 | 1
---@return integer?, T
local function binary_search(value, values, key_func)
    local low, high = 1, #values

    while low <= high do
        local mid = math.floor(low + (high - low) / 2)
        local comp = key_func(value, values[mid])

        if comp == 0 then
            return mid, values[mid]
        elseif comp == -1 then
            low = mid + 1
        else
            high = mid - 1
        end
    end

    return nil, nil
end

---@class terminal-diagnostics.SortedListOptions
---@field key_func fun(value: unknown): unknown
---@field sorted   boolean?

---@param values unknown[]?
---@param options terminal-diagnostics.SortedListOptions?
---@return terminal-diagnostics.SortedList
function SortedList.new(values, options)
    local _options = options or {}
    local key_func = _options.key_func or default_key_func
    local sorted_values = values or {}

    if not _options.sorted and sorted_values and #sorted_values > 0 then
        table.sort(sorted_values, function(value1, value2)
            return key_func(value1) < key_func(value2)
        end)
    end

    return setmetatable({
        _values = sorted_values,
        _key_func = key_func,
    }, SortedList)
end

function SortedList:add(value)
    local position, _ = self:_find_position(value)

    assert(
        position,
        ("SortedList unexpected did not find a position for value: '%s'"):format(
            vim.inspect(value)
        )
    )

    table.insert(self._values, position, value)
end

---@param value unknown
---@return boolean
function SortedList:remove(value)
    local position, _ = self:_find_position(value)

    if not position then
        return false
    end

    table.remove(self._values, position)

    return true
end

---@param value unknown
---@return unknown
function SortedList:find(value)
    local _, result = self:_find_position(value)

    return result
end

---@param value unknown
---@param count integer
---@return unknown
function SortedList:find_closest(value, count)
    local position, _ = self:_find_position(value)
    local other = self._values[position + (count > 0 and 1 or -1)]

    if math.abs(count) > 1 then
        local new_position = position + count - 1
    end
end

---@return integer?, unknown?
function SortedList:_find_position(value)
    return binary_search(value, self._values, self._key_func)
end

return SortedList
