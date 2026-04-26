local cursor = {}

---@param func fun()
function cursor.keep_cursor(func)
    local _cursor = vim.api.nvim_win_get_cursor(0)

    func()

    vim.api.nvim_win_set_cursor(0, _cursor)
end

---@return { [1]: integer, [2]: integer }
function cursor.get()
    return vim.api.nvim_win_get_cursor(0)
end

return cursor
