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

--- Same as utils.cursor.get but return an api indexed position
---@return { [1]: integer, [2]: integer }
function cursor.api_get()
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))

    return { lnum - 1, col }
end

return cursor
