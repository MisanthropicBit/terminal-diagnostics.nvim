local open = {}

local notify = require("terminal-diagnostics.notify")
local ui = require("terminal-diagnostics.ui")

---@enum terminal-diagnostics.OpenType
open.OpenType = {
    Split = "split",
    Vertical = "vertical",
    Tab = "tab",
    Edit = "edit",
    Preview = "preview",
    Float = "float",
}

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

    if type == open.OpenType.Split then
        vim.cmd.split(path)
    elseif type == open.OpenType.Vertical then
        vim.cmd("vertical split " .. path)
    elseif type == open.OpenType.Tab then
        vim.cmd.tabnew(path)
    elseif type == open.OpenType.Edit then
        vim.cmd.edit(path)
    elseif type == open.OpenType.Preview then
        -- TODO: Set cursor in preview window
        vim.cmd.pedit(path)
    elseif type == open.OpenType.Float then
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
                vim.api.nvim_win_set_cursor(
                    0,
                    { result.lnum, result.col - 1 }
                )
            end,
        })
    else
        assert(false, ("Invalid open type '%s'"):format(type))
    end

    if type ~= open.OpenType.Preview and result.lnum and result.col then
        vim.api.nvim_win_set_cursor(0, { result.lnum, result.col - 1 })
    end
end

---@param options terminal-diagnostics.OpenOptions
function open.open(options)
    local buffer = vim.api.nvim_get_current_buf()
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(buffer)

    if not result then
        notify.error("Found no matches under cursor")
        return
    end

    local data = result.command_spec:matcher():extract_values(result.results)

    if not data or #data.paths == 0 then
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
