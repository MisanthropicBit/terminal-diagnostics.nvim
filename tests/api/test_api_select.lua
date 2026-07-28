local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local td = require("terminal-diagnostics")

---@return integer[][]
local function get_visual_selection_pos()
    return { vim.fn.getpos("."), vim.fn.getpos("v") }
end

local T = new_set({
    hooks = {
        pre_once = function()
            vim.cmd.edit("test-files/tsc.txt")
        end,
        post_case = function()
            vim.cmd([[normal! \<esc>]])
        end
    },
})

T["api/select/selects inner match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 })

    td.select()

    eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 77, 0 }, -- FIX: 77?
    })
end

T["api/select/selects no inner match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 9 })

    td.select()

    eq(vim.fn.mode(), "n")
    eq(vim.api.nvim_win_get_cursor(0), { 6, 9 })
end

T["api/select/selects inner match at cursor at very start"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    td.select()

    -- eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 77, 0 },
    })
end

T["api/select/selects inner match at cursor at very end"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 74 })

    td.select()

    eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 77, 0 },
    })
end

T["api/select/selects inner match with lookahead when not on match"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    td.select({ lookahead = true })

    eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 75, 0 },
    })
end

-- TODO: Test outer selection

return T
