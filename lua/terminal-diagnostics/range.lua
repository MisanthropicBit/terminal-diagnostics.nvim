local range = {}

---@class terminal-diagnostics.Position Api-indexed position
---@field lnum integer
---@field col  integer

---@class terminal-diagnostics.Range Api-indexed range denoted by two positions
---@field from terminal-diagnostics.Position
---@field to   terminal-diagnostics.Position

---@param _range terminal-diagnostics.Range
---@param lnum integer
---@return boolean
function range.contains(_range, lnum)
    return lnum >= _range.from.lnum and lnum <= _range.to.lnum
end

---@param _range terminal-diagnostics.Range
---@param lnum integer
---@return -1 | 0 | 1
function range.compare(_range, lnum)
    if lnum < _range.from.lnum then
        return -1
    elseif lnum > range.to.lnum then
        return 1
    else
        return 0
    end
end

--- Combine several range into one range encompaasing them all
---@param ranges terminal-diagnostics.Range[]
---@return terminal-diagnostics.Range
function range.combine(ranges)
    ---@type terminal-diagnostics.Range
    local encompassing_range = {
        from = { lnum = math.huge, col = math.huge },
        to = { lnum = -1, col = -1 }
    }

    for _, _range in ipairs(ranges) do
        if _range.from.lnum < encompassing_range.from.lnum then
            encompassing_range.from.lnum = _range.from.lnum
        end

        if _range.from.col < encompassing_range.from.col then
            encompassing_range.from.col = _range.from.col
        end

        if _range.to.lnum > encompassing_range.to.lnum then
            encompassing_range.to.lnum = _range.to.lnum
        end

        if _range.to.col > encompassing_range.to.col then
            encompassing_range.to.col = _range.to.col
        end
    end

    return encompassing_range
end

return range
