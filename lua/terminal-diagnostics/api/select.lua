local select = {}

local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.SelectOptions
---@field lookahead boolean? Scan forward and try to find a match
---@field outer     boolean? Select the "outer" (instead of inner) error message

local block_visual_mode = "\22"

---@param mode string
---@return boolean
local function is_visual_mode(mode)
    return vim.tbl_contains({ "v", "V", block_visual_mode }, mode)
end

local function handle_lookahead(outer)
    local jump = require("terminal-diagnostics.api.jump")

    if not outer then
        return jump.jump({
            count = 1,
            wrap = false,
        })
    end

    local prev = jump.jump({
        count = -1,
        wrap = false,
    })

    local next = jump.jump({
        count = 1,
        wrap = false,
    })

    if not prev then
        return next
    else
        -- TODO:
        -- 1. Get the first parse result for prev
        local parser = prev.command_spec:parser()
        local parse_results = parser:parse_buffer(0, {
            offset = prev.match.from.lnum,
            count = 1,
        })

        if #parse_results == 1 and parse_results[1].context then
            local context = parse_results[1].context
            ---@cast context -nil

            local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
            col = col + 1

            if lnum >= context.range.start and lnum <= context.range.end_ then
                return prev
            end
        end

        if next then
            return next
        end
    end
end

---@param cursor_result terminal-diagnostics.ApiResult?
---@param options terminal-diagnostics.SelectOptions
---@return terminal-diagnostics.Range?
local function handle_inner_select(cursor_result, options)
    if cursor_result then
        return {
            start = cursor_result.results[1].match.from,
            end_ = cursor_result.results[1].match.to,
        }
    end

    if not options.lookahead then
        return
    end

    local result = require("terminal-diagnostics.api.jump").jump({
        count = 1,
        wrap = false,
    })

    if result then
        return {
            start = result.results[1].match.from,
            end_ = result.results[1].match.to,
        }
    end
end

---@param parser terminal-diagnostics.parser.Parser
---@param offset integer
---@return terminal-diagnostics.parser.ParseResult?
local function get_single_parse_result_with_context(parser, offset)
    local parse_results = parser:parse_buffer(0, {
        offset = offset,
        count = 1,
    })

    if #parse_results == 1 and parse_results[1].context then
        return parse_results[1]
    end
end

---@param cursor_result terminal-diagnostics.ApiResult?
---@param options terminal-diagnostics.SelectOptions
---@return terminal-diagnostics.Range?
local function handle_outer_select(cursor_result, options)
    -- 1. If there is a result on the cursor, parse once
    if cursor_result then
        -- TODO: Check if parser even supports context
        local parse_result = get_single_parse_result_with_context(
            cursor_result.command_spec:parser(),
            cursor_result.results[1].match.from.lnum
        )

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            return {
                start = cursor_result.results[1].match.from,
                end_ = context.range.end_,
            }
        else
            return {
                start = cursor_result.results[1].match.from,
                end_ = cursor_result.results[1].match.to,
            }
        end
    end

    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    col = col + 1

    -- 2. Check if cursor is on an error context line
    local prev = require("terminal-diagnostics.api.jump").jump({
        count = -1,
        wrap = false,
    })

    if prev then
        local parse_result = get_single_parse_result_with_context(
            prev.command_spec:parser(),
            prev.results[1].match.from.lnum
        )

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if utils.range.contains(context.range, lnum) then
                return {
                    start = parse_result.range.start,
                    end_ = context.range.end_,
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
        local parse_result = get_single_parse_result_with_context(
            next.command_spec:parser(),
            next.results[1].match.from.lnum
        )

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if utils.range.contains(context.range, lnum) then
                return {
                    start = parse_result.range.start,
                    end_ = context.range.end_,
                }
            end
        end
    end
end

---@param options terminal-diagnostics.SelectOptions?
function select.select(options)
    local _options = options or {}
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(0, {})
    local range ---@type terminal-diagnostics.Range?

    if _options.outer then
        range = handle_outer_select(result, _options)
    else
        range = handle_inner_select(result, _options)
    end

    if not range then
        return
    end

    local from, to = range.start, range.end_

    local mode = vim.api.nvim_get_mode().mode

    -- Enter visual mode if not already in visual mode
    if not is_visual_mode(mode) then
        vim.cmd.normal({ "v", bang = true })
    end

    vim.api.nvim_win_set_cursor(0, { to.lnum, to.col })
    vim.cmd([[normal! o]])
    vim.api.nvim_win_set_cursor(0, { from.lnum, from.col })
end

return select
