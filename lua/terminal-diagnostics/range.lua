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

return range
