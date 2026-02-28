local cursor = {}

local builtins = require("terminal-diagnostics.builtins")

---@param location { [1]: terminal-diagnostics.Match, [2]: terminal-diagnostics.MatchResult }?
---@return boolean
local function last_jump_location_is_valid(location)
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
    local match, data
    local last_jump_location = require("terminal-diagnostics.api.jump").get_last_jump_position()
    local valid = last_jump_location_is_valid(last_jump_location)

    if valid then
        ---@cast last_jump_location -nil
        match = last_jump_location[1]
    else
        last_jump_location = nil
        local command_specs = builtins.get()

        for _, command_spec in ipairs(command_specs) do
            local matcher = command_spec:matcher()
            match, data = matcher.match_at_cursor({ buffer = buffer })

            if match then
                break
            end
        end
    end

    if not match then
        return
    end

    return { match = match, data = data }
end

return cursor
