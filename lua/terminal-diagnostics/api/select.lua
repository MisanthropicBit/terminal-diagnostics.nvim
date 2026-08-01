local select = {}

local api_utils = require("terminal-diagnostics.api.api_utils")
local range = require("terminal-diagnostics.range")
local utils = require("terminal-diagnostics.utils")

---@enum terminal-diagnostics.SelectField
select.SelectField = {
    Path = "path",
    Lnum = "lnum",
    Col = "col",
    Severity = "severity",
    Code = "code",
    Message = "message",
}

---@class terminal-diagnostics.SelectOptions
---@field lookahead boolean? Scan forward and try to find a match
---@field outer     boolean? Select the "outer" (instead of inner) error message
---@field field     terminal-diagnostics.SelectField?

local block_visual_mode = "\22"

---@param mode string
---@return boolean
local function is_visual_mode(mode)
    return vim.tbl_contains({ "v", "V", block_visual_mode }, mode)
end

---@param cursor_result terminal-diagnostics.ApiResult?
---@param options terminal-diagnostics.SelectOptions
---@return terminal-diagnostics.ApiResult?
local function handle_inner_select(cursor_result, options)
    -- 1. If there is a result on the cursor, use taht
    if cursor_result then
        -- TODO: Use the result that overlaps with the cursor
        return cursor_result
    end

    local lnum, _ = unpack(utils.cursor.api_get())

    -- 2. Check if cursor is on an error context line
    local prev = require("terminal-diagnostics.api.jump").jump({
        count = -1,
        wrap = false,
    })

    if prev then
        if not prev.command_spec:parser():has_context() then
            return
        end

        local parse_result = api_utils.get_single_parse_result_with_context(prev)

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if range.contains(context.range, lnum) then
                return prev
            end
        end
    end

    if not options.lookahead then
        return
    end

    return require("terminal-diagnostics.api.jump").jump({
        count = 1,
        wrap = false,
    })
end

---@param cursor_result terminal-diagnostics.ApiResult?
---@param options terminal-diagnostics.SelectOptions
---@return terminal-diagnostics.ApiResult?, terminal-diagnostics.Range?
local function handle_outer_select(cursor_result, options)
    -- 1. If there is a result on the cursor, parse once
    if cursor_result then
        -- If parser does not support context lines just return the result
        if not cursor_result.command_spec:parser():has_context() then
            return cursor_result
        end

        local parse_result = api_utils.get_single_parse_result_with_context(cursor_result)

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            return cursor_result, {
                start = cursor_result.matches[1].range.from,
                end_ = context.range.to,
            }
        else
            return cursor_result, {
                start = cursor_result.matches[1].range.from,
                end_ = cursor_result.matches[1].range.to,
            }
        end
    end

    local lnum, _ = unpack(utils.cursor.api_get())

    -- 2. Check if cursor is on an error context line
    local prev = require("terminal-diagnostics.api.jump").jump({
        count = -1,
        wrap = false,
    })

    if prev then
        if not prev.command_spec:parser():has_context() then
            return
        end

        local parse_result = api_utils.get_single_parse_result_with_context(prev)

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if range.contains(context.range, lnum) then
                return prev, {
                    start = parse_result.range.from,
                    end_ = context.range.to,
                }
            end
        end
    end

    if not options.lookahead then
        return
    end

    -- 3. Do lookahead
    local next = require("terminal-diagnostics.api.jump").jump({
        count = 1,
        wrap = false,
    })

    if not next then
        return
    end

    if next then
        if not next.command_spec:parser():has_context() then
            return next
        end

        local parse_result = api_utils.get_single_parse_result_with_context(next)

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if range.contains(context.range, lnum) then
                return {
                    start = parse_result.range.from,
                    end_ = context.range.to,
                }
            end
        end
    end
end

---@param options terminal-diagnostics.SelectOptions?
function select.select(options)
    -- TODO: Validate arguments for public all api functions

    local _options = options or {}
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(0)
    local _range ---@type terminal-diagnostics.Range?

    if _options.outer then
        result, _range = handle_outer_select(result, _options)
    else
        result = handle_inner_select(result, _options)
    end

    if not result then
        return
    end

    local from, to = result.matches[1].range.from, result.matches[1].range.to

    if _options.outer then
        ---@cast _range -nil
        from, to = _range.from, _range.to
    end

    -- if _options.field then
    --     local subgroups = patterns.parse_subgroups(result.results[1].match.text, result.results[1].spec)
    --     local subgroup = subgroups[_options.field]
    --
    --     from = { lnum = from.lnum, col = subgroup.start_col }
    --     to = { lnum = to.lnum, col = subgroups.end_col}
    -- end

    local mode = vim.api.nvim_get_mode().mode

    -- Enter visual mode if not already in visual mode
    if not is_visual_mode(mode) then
        vim.cmd.normal({ "v", bang = true })
    end

    vim.api.nvim_win_set_cursor(0, { to.lnum + 1, to.col })
    vim.cmd([[normal! o]])
    vim.api.nvim_win_set_cursor(0, { from.lnum + 1, from.col })
end

return select
