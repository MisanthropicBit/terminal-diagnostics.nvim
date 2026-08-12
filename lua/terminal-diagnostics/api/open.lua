local open = {}

local notify = require("terminal-diagnostics.notify")
local ui = require("terminal-diagnostics.ui")
local OpenType = require("terminal-diagnostics.api.open_type")
local range = require("terminal-diagnostics.range")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.OpenOptions
---@field type terminal-diagnostics.OpenType

---@param type terminal-diagnostics.OpenType
---@param result terminal-diagnostics.MatchResult
---@param path string
local function open_match(type, result, path)
    if vim.fn.filereadable(path) == 0 then
        notify.error("File '%s' is not readable", path)
        return
    end

    if type == OpenType.Split then
        vim.cmd.split(path)
    elseif type == OpenType.Vertical then
        vim.cmd("vertical split " .. path)
    elseif type == OpenType.Tab then
        vim.cmd.tabnew(path)
    elseif type == OpenType.Edit then
        vim.cmd.edit(path)
    elseif type == OpenType.Preview then
        -- TODO: Set cursor in preview window
        vim.cmd.pedit(path)
    elseif type == OpenType.Float then
        ui.float.open_preview({
            target = path,
            width = 0.5,
            height = 0.45,
            enter = true,
            title = path,
            title_pos = "left",
            border = "rounded",
            close_on_move = true,
            post_open_hook = function()
                vim.api.nvim_win_set_cursor(0, { result.lnum, result.col - 1 })
            end,
        })
    else
        assert(false, ("Invalid open type '%s'"):format(type))
    end

    if type ~= OpenType.Preview and result.lnum and result.col then
        vim.api.nvim_win_set_cursor(0, { result.lnum, result.col - 1 })
    end
end

---@param lnum integer
---@return terminal-diagnostics.ApiResult?
local function find_previous_result(lnum)
    -- If there is no result at the cursor try finding a previous match and see
    -- if the cursor is on some context line
    local prev = require("terminal-diagnostics.api.jump").jump({
        count = -1,
        wrap = false,
        keep_cursor = true,
    })

    if prev then
        if not prev.command_spec:parser():has_context() then
            return
        end

        local api_utils = require("terminal-diagnostics.api.api_utils")
        local parse_result = api_utils.get_single_parse_result_with_context(prev)

        if parse_result then
            local context = parse_result.context
            ---@cast context -nil

            if range.contains(context.range, lnum) then
                return prev
            end
        end
    end
end

---@param options terminal-diagnostics.OpenOptions
function open.open(options)
    local buffer = vim.api.nvim_get_current_buf()
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(buffer)
    local lnum, _ = unpack(utils.cursor.api_get())

    -- If there is no result at the cursor try finding a previous match and see
    -- if the cursor is on some context line
    if not result then
        result = find_previous_result(lnum)
    end

    if not result then
        notify.error("Found no matches")
        return
    end

    local data = result.command_spec:matcher():extract_values(result.matches)

    if not data or not data.paths or #data.paths == 0 then
        notify.error("Match did not contain a path to open")
        return
    end

    if #data.paths == 1 then
        open_match(options.type, data, data.paths[1])
        return
    end

    vim.ui.select(data.paths, {
        prompt = ("Found %d paths, please select one > "):format(#data.paths),
    }, function(item)
        if item then
            open_match(options.type, data, item)
        end
    end)
end

return open
