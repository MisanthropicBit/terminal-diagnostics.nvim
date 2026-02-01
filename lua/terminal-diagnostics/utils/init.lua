local function keep_cursor(func)
    local cursor = vim.api.nvim_win_get_cursor(0)

    func()

    vim.api.nvim_win_set_cursor(0, cursor)
end

---@return { [1]: integer, [2]: integer }
local function get_cursor()
    return vim.api.nvim_win_get_cursor(0)
end

return {
    patterns = require("terminal-diagnostics.utils.patterns"),
    keep_cursor = keep_cursor,
    get_cursor = get_cursor,
}
