local open = {}

local api_utils = require("terminal-diagnostics.api.api_utils")
local notify = require("terminal-diagnostics.notify")
local ui = require("terminal-diagnostics.ui")
local OpenType = require("terminal-diagnostics.api.open_type")

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

---@param options terminal-diagnostics.OpenOptions
function open.open(options)
    local buffer = vim.api.nvim_get_current_buf()
    local result, parse_result = api_utils.find_parse_result_at_cursor(buffer)

    if not result or not parse_result then
        notify.error("Found no matches")
        return
    end

    local data = parse_result.values

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
