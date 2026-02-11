local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local api = require("terminal-diagnostics.api")


local T = new_set({
    hooks = {
        pre_once = function()
            vim.cmd.edit("test-files/tsc.txt")
        end
    }
})

T["api/jump"] = new_set()

T["api/jump"]["jumps to next match"] = function()
    eq(vim.api.nvim_win_get_cursor(0), { 1, 0 })
    api.jump()
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

T["api/jump"]["does not move cursor if no next match"] = function()
    vim.api.nvim_win_set_cursor(0, { 7, 0 })

    api.jump({ count = 1 })
    eq(vim.api.nvim_win_get_cursor(0), { 7, 0 })
end

T["api/jump"]["jumps to next match by wrapping"] = function()
    vim.api.nvim_win_set_cursor(0, { 7, 0 })

    api.jump({ count = 1, wrap = true })
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

T["api/jump"]["jumps to previous match"] = function()
    vim.api.nvim_win_set_cursor(0, { 9, 0 })

    api.jump({ count = -1 })
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

T["api/jump"]["does not move cursor if no previous match"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    api.jump({ count = -1 })
    eq(vim.api.nvim_win_get_cursor(0), { 2, 0 })
end

T["api/jump"]["jumps to previous match by wrapping"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    api.jump({ count = -1, wrap = true })
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

return T
