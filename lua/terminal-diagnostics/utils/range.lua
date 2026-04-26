local range = {}

---@param _range terminal-diagnostics.Range
---@param lnum integer
---@return boolean
function range.contains(_range, lnum)
    return lnum >= _range.start.lnum and lnum <= _range.end_.lnum
end

return range
