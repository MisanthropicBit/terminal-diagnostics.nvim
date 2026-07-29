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
T["patterns/parse_subgroup"] = new_set()

T["patterns/parse_subgroup"]["parses single line subgroups"] = function()
    local result = patterns.parse_subgroups(match1.text, test_spec)

    local lines = vim.split(match1.text, "\n", { plain = true, trimempty = true })

    eq(lines[result.path.start_lnum]:sub(result.path.start_col + 1, result.path.end_col), "main.ts")
    eq(lines[result.lnum.start_lnum]:sub(result.lnum.start_col + 1, result.lnum.end_col), "6")
    eq(lines[result.col.start_lnum]:sub(result.col.start_col + 1, result.col.end_col), "26")
    eq(lines[result.severity.start_lnum]:sub(result.severity.start_col + 1, result.severity.end_col), "error")
    eq(lines[result.code.start_lnum]:sub(result.code.start_col + 1, result.code.end_col), "2322")
    eq(lines[result.message.start_lnum]:sub(result.message.start_col + 1, result.message.end_col), "Type 'null' is not assignable to type 'Person'.")
end

T["patterns/parse_subgroup"]["parses multiline subgroups"] = function()
    local text = [[error[E0000]: main error message
  --> file.rs:14:5]]

    local result = patterns.parse_subgroups(
        text,
        require("terminal-diagnostics.command_specs.rustc"):matcher():specs()[1]
    )

    local lines = vim.split(text, "\n", { plain = true, trimempty = true })

    eq(lines[result.path.start_lnum]:sub(result.path.start_col + 1, result.path.end_col), "file.rs")
    eq(lines[result.lnum.start_lnum]:sub(result.lnum.start_col + 1, result.lnum.end_col), "14")
    eq(lines[result.col.start_lnum]:sub(result.col.start_col + 1, result.col.end_col), "5")
    eq(lines[result.severity.start_lnum]:sub(result.severity.start_col + 1, result.severity.end_col), "error")
    eq(lines[result.code.start_lnum]:sub(result.code.start_col + 1, result.code.end_col), "E0000")
    eq(lines[result.message.start_lnum]:sub(result.message.start_col + 1, result.message.end_col), "main error message")
end

return T
