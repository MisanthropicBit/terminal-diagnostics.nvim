local new_set = MiniTest.new_set
local eq, neq = MiniTest.expect.equality, MiniTest.expect.no_equality

local api = require("terminal-diagnostics.api")

local spec = {
    name = "tsc",
    regex =
    "\\v^([^[:space:]].*)[\\(:](\\d+)[,:](\\d+)%(\\):\\s+|\\s+-\\s+)(error|warning|info)\\s+TS(\\d+)\\s*:\\s*(.*)$",
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local match = {
    text = {
        "main.ts:6:5 - error TS2322: Type 'null' is not assignable to type 'Person'.",
    },
    submatches = {
        "main.ts",
        "6",
        "5",
        "error",
        "2322",
        "Type 'null' is not assignable to type 'Person'.",
        "",
        "",
        "",
    },
    from = {
        lnum = 4,
        col = 1,
    },
    to = {
        lnum = 4,
        col = 75,
    },
    spec = spec,
}

local data = {
    name = "tsc",
    path = "main.ts",
    lnum = 6,
    col = 5,
    severity = 1,
    code = "2322",
    message = "Type 'null' is not assignable to type 'Person'.",
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

    local result = api.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 22 })

    neq(result, nil) ---@cast result -nil
    eq(result.match, match)
    eq(result.data, data)
end

T["api/find_at_cursor/finds no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 9 })

    local result = api.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 6, 9 })
    eq(result, nil)
end

T["api/find_at_cursor/finds match at cursor at very start"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local result = api.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })

    neq(result, nil) ---@cast result -nil
    eq(result.match, match)
    eq(result.data, data)
end

T["api/find_at_cursor/finds match at cursor at very end"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 74 })

    local result = api.find_at_cursor(0)

    eq(vim.api.nvim_win_get_cursor(0), { 4, 74 })

    neq(result, nil) ---@cast result -nil
    eq(result.match, match)
    eq(result.data, data)
end

return T
