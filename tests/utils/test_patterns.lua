local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local utils = require("terminal-diagnostics.utils")

local spec = {
    name = "tsc",
    pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local positive_match1 = {
    text = {
        "main.ts:6:26 - error TS2322: Type 'null' is not assignable to type 'Person'.",
    },
    submatches = {
        "main.ts",
        "6",
        "26",
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
        col = 76,
    },
    spec = spec,
}

local positive_match2 = {
    text = {
        "main.ts:7:27 - error TS2322: Type 'undefined' is not assignable to type 'Person'.",
    },
    submatches = {
        "main.ts",
        "7",
        "27",
        "error",
        "2322",
        "Type 'undefined' is not assignable to type 'Person'.",
        "",
        "",
        "",
    },
    from = {
        lnum = 9,
        col = 1,
    },
    to = {
        lnum = 9,
        col = 81,
    },
    spec = spec,
}

local T = new_set({
    hooks = {
        pre_case = function()
            vim.cmd.edit("test-files/tsc.txt")
        end,
    },
})

T["utils"] = new_set()
T["utils/patterns/find"] = new_set()
T["utils/patterns/find_at_cursor"] = new_set()

T["utils/patterns/find"]["finds a match and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 3 }) -- On the 's' of 'tsc'

    local match = utils.patterns.find(0, spec, 1)

    eq(match, positive_match1)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 3 })
end

T["utils/patterns/find"]["finds no match at the beginning of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 1 })

    local match = utils.patterns.find(0, spec, 1)

    eq(match, positive_match2)
end

T["utils/patterns/find"]["finds no match at the end of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 75 })

    local match = utils.patterns.find(0, spec, 1)

    eq(match, positive_match2)
end

T["utils/patterns/find"]["finds no match"] = function()
    vim.api.nvim_win_set_cursor(0, { 10, 0 })

    local match = utils.patterns.find(0, spec, 1)

    eq(match, nil)
end

T["utils/patterns/find_at_cursor"]["finds a match at cursor in middle of text and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 }) -- On the 'S' in 'TS2322'

    local match = utils.patterns.find_at_cursor(0, spec)

    eq(match, positive_match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 22 })
end

T["utils/patterns/find_at_cursor"]["finds a match at cursor at beginning of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local match = utils.patterns.find_at_cursor(0, spec)

    eq(match, positive_match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

T["utils/patterns/find_at_cursor"]["finds a match at cursor at end of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 75 })

    local match = utils.patterns.find_at_cursor(0, spec)

    eq(match, positive_match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 75 })
end

T["utils/patterns/find_at_cursor"]["finds no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 5, 0 })

    local match = utils.patterns.find_at_cursor(0, spec)

    eq(match, nil)
end

return T
