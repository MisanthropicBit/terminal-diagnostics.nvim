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

    if not prev or not prev.command_spec:parser():has_context() then
        return
    end

    local parse_result = api_utils.get_single_parse_result_with_context(prev)

    if not parse_result then
        return
    end

    local context = parse_result.context
    ---@cast context -nil

    -- Check that the parse result actually contains the cursor line number
    if range.contains(context.range, lnum) then
        return prev, parse_result
    end
end

---@param lnum integer
---@param matches terminal-diagnostics.Match[]
---@return terminal-diagnostics.Match?
local function find_match_on_line(lnum, matches)
    local cur_match

    for idx = 1, #matches do
        local match = matches[idx]

        if not match then
            break
        end

        if lnum == match.range.from.lnum then
            cur_match = match
        end
    end

    return cur_match
end

---@param buffer integer
---@return terminal-diagnostics.ApiResult?
---@return terminal-diagnostics.parser.ParseResult?
function api_utils.find_parse_result_at_cursor(buffer)
    local result = cursor.find_at_cursor(buffer)

    if result then
        local lnum, _ = unpack(utils.cursor.api_get())
        local match = find_match_on_line(lnum, result.matches)

        if not match then
            return
        end

        return result, api_utils.get_single_parse_result_with_context(result, match.range.from.lnum + 1)
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
---@param offset integer?
---@return terminal-diagnostics.parser.ParseResult?
function api_utils.get_single_parse_result_with_context(api_result, offset)
    -- NOTE: For header parsers we can either:
    -- 1. Find the earliest match (lnum) and use that as the parser offset to make sure
    --    that we include the header. The issue is that we cannot use count = 1 since
    --    we don't know when to stop
    -- 2. Parse from the match at the cursor and then make logic in the HeaderParser to
    --    look back. The issue is that we then need to include all lines from the buffer
    --    to make sure the header is included
    -- 3. Find the earliest match (lnum) and use that as the parser offset to make sure
    --    that we include the header then create a result_offset option that tells the
    --    parser when to start considering count = X.
    -- 4. We already found the matches we need (the api_result). Pass that information
    --    to the parser so it can use the header match directly. If getting count = X
    --    results, where X > 1, we need to match on the header first so that we can
    --    overwrite the last_header_match with a new header but otherwise fall back
    --    to the one supplied as an option.
    --
    -- Sticking with solution 4 for now. Solution 3 might be better in the long run

    local _offset = offset or api_result.matches[1].range.from.lnum

    local parse_results = api_result.command_spec:parser():parse_buffer(0, {
        offset = _offset,
        count = 1,
        extract = true,
        last_header_match = api_result.matches[1]
    })

    if #parse_results == 1 then
        return parse_results[1]
    end
end

return api_utils
