local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local td = require("terminal-diagnostics")
local tsc_command_spec = require("terminal-diagnostics.command_specs.tsc")

local test_matcher = tsc_command_spec:matcher()
local test_spec = test_matcher:specs()[1]

local match = {
    text = "main.ts:6:26 - error TS2322: Type 'null' is not assignable to type 'Person'.",
    submatches = {
        "main.ts",
        "6",
        "26",
        "error",
        "2322",
        "Type 'null' is not assignable to type 'Person'.",
    },
    from = {
        lnum = 3,
        col = 0,
    },
    to = {
        lnum = 3,
        col = 76,
    },
    spec = test_spec,
}

local T = new_set({
    hooks = {
        pre_once = function()
            vim.cmd.edit("test-files/tsc.txt")
        end
    }
})

T["api/find_at_cursor/finds match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 })

    local result = td.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 22 })

    eq(result.command_spec:name(), tsc_command_spec:name())
    eq(result.matches, { match })
end

T["api/find_at_cursor/finds no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 9 })

    local result = td.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 6, 9 })
    eq(result, nil)
end

T["api/find_at_cursor/finds match at cursor at very start"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local result = td.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })

    eq(result.command_spec:name(), tsc_command_spec:name())
    eq(result.matches, { match })
end

T["api/find_at_cursor/finds match at cursor at very end"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 75 })

    local result = td.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 75 })

    eq(result.command_spec:name(), tsc_command_spec:name())
    eq(result.matches, { match })
end

return T
