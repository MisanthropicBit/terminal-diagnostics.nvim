local range = {}

---@param _range terminal-diagnostics.Range
---@param lnum integer
---@return boolean
function range.contains(_range, lnum)
    return lnum >= _range.start.lnum and lnum <= _range.end_.lnum
end

---@param _range terminal-diagnostics.Range
---@param lnum integer
---@return -1 | 0 | 1
function range.compare(_range, lnum)
    if lnum < _range.start.lnum then
        return -1
    elseif lnum > range.end_.lnum then
        return 1
    else
        return 0
    end
end

return range
