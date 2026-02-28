local open = {}

local notify = require("terminal-diagnostics.notify")
local ui = require("terminal-diagnostics.ui")

---@enum terminal-diagnostics.OpenType
local OpenType = {
    Split = "split",
    Vertical = "vertical",
    Tab = "tab",
    Edit = "edit",
    Preview = "preview",
    Float = "float",
}

---@param type terminal-diagnostics.OpenType
---@param result terminal-diagnostics.ApiResult
local function open_match(type, result)
    local abspath = vim.fs.abspath(result.data.path)

    if vim.fn.filereadable(abspath) == 0 then
        notify.error("File '%s' is not readable", abspath)
        return
    end

    if type == OpenType.Split then
        vim.cmd.split(abspath)
    elseif type == OpenType.Vertical then
        vim.cmd("vertical split " .. abspath)
    elseif type == OpenType.Tab then
        vim.cmd.tabnew(abspath)
    elseif type == OpenType.Edit then
        vim.cmd.edit(abspath)
    elseif type == OpenType.Preview then
        -- TODO: Set cursor in preview window
        vim.cmd.pedit(abspath)
    elseif type == OpenType.Float then
        ui.float.open_preview({
            target = abspath,
            width = 0.5,
            height = 0.45,
            enter = true,
            title = abspath,
            title_pos = "left",
            border = "rounded",
            close_on_move = true,
            post_open_hook = function()
                vim.api.nvim_win_set_cursor(
                    0,
                    { result.data.lnum, result.data.col - 1 }
                )
            end,
        })
    else
        assert(false, ("Invalid open type '%s'"):format(type))
    end

    if type ~= OpenType.Preview then
        vim.api.nvim_win_set_cursor(0, { result.data.lnum, result.data.col - 1 })
    end
end

---@param options table
function open.open(options)
    local buffer = vim.api.nvim_get_current_buf()
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(buffer)

    if not result then
        notify.error("Found no matches under cursor")
        return
    elseif not result.data.path then
        notify.error("Match does not contain a path to open")
        return
    end

    open_match(options.type, result)
end

return open
