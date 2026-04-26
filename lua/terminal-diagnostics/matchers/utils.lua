local utils = {}

---@param spec terminal-diagnostics.MatchSpec
---@return boolean
function utils.spec_has_info(spec)
    local has_info = spec.path
        or spec.lnum
        or spec.col
        or spec.severity
        or spec.code
        or spec.message

    return has_info ~= nil
end

---@param spec terminal-diagnostics.MatchSpec
---@return boolean
function utils.spec_has_fileinfo(spec)
    return spec.path ~= nil
end

return utils
