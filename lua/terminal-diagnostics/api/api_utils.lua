local api_utils = {}

local cursor = require("terminal-diagnostics.api.cursor")
local range = require("terminal-diagnostics.range")
local utils = require("terminal-diagnostics.utils")

---@param lnum integer
---@return terminal-diagnostics.ApiResult?
---@return terminal-diagnostics.parser.ParseResult?
local function find_previous_result(lnum)
    -- If there is no result at the cursor try finding a previous match and see
    -- if the cursor is on some context line
    local prev = require("terminal-diagnostics.api.jump").jump({
        count = -1,
        wrap = false,
        keep_cursor = true,
    })

    if not prev then
        return
    end

    if not prev.command_spec:parser():has_context() then
        return
    end

    local parse_result = api_utils.get_single_parse_result_with_context(prev)

    if parse_result then
        local context = parse_result.context
        ---@cast context -nil

        -- Check that the parse result actually contains the cursor line number
        if range.contains(context.range, lnum) then
            return prev, parse_result
        end
    end
end

---@param buffer integer
---@return terminal-diagnostics.ApiResult?
---@return terminal-diagnostics.parser.ParseResult?
function api_utils.find_parse_result_at_cursor(buffer)
    local result = cursor.find_at_cursor(buffer)

    if result then
        return result, api_utils.get_single_parse_result_with_context(result)
    end

    -- If there is no result at the cursor try finding a previous match and see
    -- if the cursor is on some context line
    local lnum, _ = unpack(utils.cursor.api_get())
    local parse_result
    result, parse_result = find_previous_result(lnum)

    if not result then
        return
    end

    return result, parse_result
end

---@param api_result terminal-diagnostics.ApiResult
---@return terminal-diagnostics.parser.ParseResult?
function api_utils.get_single_parse_result_with_context(api_result)
    local parse_results = api_result.command_spec:parser():parse_buffer(0, {
        offset = api_result.matches[1].range.from.lnum,
        count = 1,
        extract = true,
    })

    if #parse_results == 1 and parse_results[1].context then
        return parse_results[1]
    end
end

return api_utils
