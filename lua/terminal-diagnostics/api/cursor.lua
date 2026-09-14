local cursor = {}

local builtins = require("terminal-diagnostics.command_specs")

---@param buffer integer
---@return terminal-diagnostics.ApiResult?
function cursor.find_at_cursor(buffer)
    local result ---@type terminal-diagnostics.ApiResult
    local jump = require("terminal-diagnostics.api.jump")
    local last_jump_result = jump.get_last_jump_result()

    if jump.last_jump_result_is_valid(last_jump_result) then
        ---@cast last_jump_result -nil
        result = last_jump_result
    else
        local command_specs = builtins.get_all()

        for _, command_spec in ipairs(command_specs) do
            local matcher = command_spec:matcher()
            local matches = matcher:match_at_cursor({ buffer = buffer })

            if #matches > 0 then
                result = {
                    command_spec = command_spec,
                    matches = matches,
                }

                break
            end
        end
    end

    return result
end

return cursor
