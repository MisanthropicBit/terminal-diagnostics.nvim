local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local patterns = require("terminal-diagnostics.patterns")

local test_spec = require("terminal-diagnostics.builtins.tsc"):matcher():specs()[1]
local tsc_test_lines = vim.fn.readfile("./test-files/tsc.txt")

local match1 = {
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

local match2 = {
    text = "main.ts:7:27 - error TS2322: Type 'undefined' is not assignable to type 'Person'.",
    submatches = {
        "main.ts",
        "7",
        "27",
        "error",
        "2322",
        "Type 'undefined' is not assignable to type 'Person'.",
    },
    from = {
        lnum = 8,
        col = 0,
    },
    to = {
        lnum = 8,
        col = 81,
    },
    spec = test_spec,
}

local T = new_set({
    hooks = {
        pre_once = function()
            vim.cmd.edit("test-files/tsc.txt")
        end,
    },
})

T["patterns/find"] = new_set()

T["patterns/find"]["finds a match and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 3 }) -- On the 's' of 'tsc'

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, match1)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 3 })
end

T["patterns/find"]["finds no match at the beginning of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 1 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, match2)
end

T["patterns/find"]["finds no match at the end of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 75 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, match2)
end

T["patterns/find"]["finds no match"] = function()
    vim.api.nvim_win_set_cursor(0, { 10, 0 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, nil)
end

T["patterns/find_at_cursor"] = new_set()

T["patterns/find_at_cursor"]["finds a match at cursor in middle of text and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 }) -- On the 'S' in 'TS2322'

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 22 })
end

T["patterns/find_at_cursor"]["finds a match at cursor at beginning of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 0 })
end

T["patterns/find_at_cursor"]["finds a match at cursor at end of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 75 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match1)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 75 })
end

T["patterns/find_at_cursor"]["finds no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 5, 0 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, nil)
end

T["patterns/find_in_lines"] = new_set()

T["patterns/find_in_lines"]["finds a match in some lines with no offset"] = function()
    local lnum = patterns.find_in_lines(tsc_test_lines, test_spec)

    eq(lnum, 3)
end

T["patterns/find_in_lines"]["finds a match in some lines with offset"] = function()
    local lnum = patterns.find_in_lines(tsc_test_lines, test_spec, 6)

    eq(lnum, 8)
end

T["patterns/find_in_lines"]["finds no match"] = function()
end

T["patterns/find_at_line"] = new_set()

T["patterns/find_at_line"]["finds a pattern at a line with no offset"] = function()
    local match = patterns.find_at_line(tsc_test_lines, test_spec, 4)

    eq(match, match1)
end

T["patterns/find_at_line"]["finds a pattern at a line with offset"] = function()
    local match = patterns.find_at_line(tsc_test_lines, test_spec, 9)

    eq(match, match2)
end

-- T["patterns/find_at_line"]["finds a pattern at a line with offset but not at first column"] = function()
--
-- end

T["patterns/find_at_line"]["finds no match"] = function()
end

-- TODO: Test multiline regexes
-- T["patterns/parse_subgroup"] = new_set()
--
-- T["patterns/parse_subgroup"]["parses tsc subgroups"] = function()
--     local result = patterns.parse_subgroups(positive_match1.text[1], test_spec)
--
--     eq(result, {
--         path = { start_col = 0, end_col = 7 },
--         lnum = { start_col = 8, end_col = 9 },
--         col = { start_col = 10, end_col = 12 },
--         severity = { start_col = 15, end_col = 20 },
--         code = { start_col = 21, end_col = 27 },
--         message = { start_col = 29, end_col = 76 },
--     })
-- end
--
-- T["patterns/parse_subgroup"]["parses jest subgroups"] = function()
--     local jest_match = "at Object.toEqual (src/fail-throws-synchronous.test.js:10:19)"
--     local jest_spec = require("terminal-diagnostics.builtins.jest"):matcher():specs()[2]
--     local result = patterns.parse_subgroups(jest_match, jest_spec)
--
--     eq(result, {
--         path = { start_col = 20, end_col = 54 },
--         lnum = { start_col = 56, end_col = 57 },
--         col = { start_col = 59, end_col = 60 },
--     })
-- end

return T
