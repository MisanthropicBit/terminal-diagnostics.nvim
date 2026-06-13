local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local api = require("terminal-diagnostics.api")

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

T["api/select/selects match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 })

    api.select()

    eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 75, 0 },
    })
end

T["api/select/selects no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 9 })

    api.select()

    -- eq(vim.fn.mode(), "n")
    eq(vim.api.nvim_win_get_cursor(0), { 6, 9 })
end

T["api/select/selects match at cursor at very start"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    api.select()

    -- eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 75, 0 },
    })
end

T["api/select/selects match at cursor at very end"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 74 })

    api.select()

    -- eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 75, 0 },
    })
end

T["api/select/selects match with lookahead when not on match"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })

    api.select({ lookahead = true })

    -- eq(vim.fn.mode(), "v")
    eq(get_visual_selection_pos(), {
        { 0, 4, 1,  0 },
        { 0, 4, 75, 0 },
    })
end

return T
