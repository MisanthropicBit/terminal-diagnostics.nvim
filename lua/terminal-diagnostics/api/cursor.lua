local cursor = {}

local builtins = require("terminal-diagnostics.builtins")

---@param location terminal-diagnostics.ApiResult?
---@return boolean
local function last_jump_result_is_valid(location)
    if not location or not location[1] then
        return false
    end

    local _, lnum, col, _ = unpack(vim.fn.getpos("."))

    if lnum >= location[1].from.lnum and lnum <= location[1].to.lnum then
        if col >= location[1].from.col and col <= location[1].to.col then
            return true
        end
    end

    return false
end

---@param buffer integer
---@parm options table
---@return terminal-diagnostics.ApiResult?
function cursor.find_at_cursor(buffer, options)
    local result ---@type terminal-diagnostics.ApiResult
    local last_jump_result = require("terminal-diagnostics.api.jump").get_last_jump_result()

    if last_jump_result_is_valid(last_jump_result) then
        ---@cast last_jump_result -nil
        result = last_jump_result
    else
        local command_specs = builtins.get()

        for _, command_spec in ipairs(command_specs) do
            local matcher = command_spec:matcher()
            local results = matcher:match_at_cursor({ buffer = buffer })

            if #results > 0 then
                result = {
                    command_spec = command_spec,
                    results = results,
                }

                break
            end
        end
    end

    return result
end

return cursor
