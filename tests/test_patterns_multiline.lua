local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local patterns = require("terminal-diagnostics.patterns")

local test_spec = require("terminal-diagnostics.command_specs.rustc"):matcher():specs()[1]
local rustc_test_lines = vim.fn.readfile("./test-files/rustc.txt")

local match1 = {
    text = "error[E0000]: main error message\n  --> file.rs:14:5",
    submatches = { "error", "E0000", "main error message", "file.rs", "14", "5" },
    from = {
        lnum = 2,
        col = 0,
    },
    to = {
        lnum = 3,
        col = 18,
    },
    spec = test_spec,
}

local match2 = {
    text = "note: sub-diagnostic message for `.span_note`\n  --> file.rs:10:4",
    submatches = { "note", "", "sub-diagnostic message for `.span_note`", "file.rs", "10", "4" },
    from = {
        lnum = 11,
        col = 0,
    },
    to = {
        lnum = 12,
        col = 18,
    },
    spec = test_spec,
}

local T = new_set({
    hooks = {
        pre_case = function()
            vim.cmd.edit("test-files/rustc.txt")
        end,
    },
})

T["patterns/find multiline"] = new_set()

T["patterns/find multiline"]["finds a match and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 3 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, match2)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 3 })
end

T["patterns/find multiline"]["finds no match at the beginning of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 12, 0 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, nil)
end

T["patterns/find multiline"]["finds no match at the end of pattern"] = function()
    vim.api.nvim_win_set_cursor(0, { 13, 17 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, nil)
end

T["patterns/find multiline"]["finds no match"] = function()
    vim.api.nvim_win_set_cursor(0, { 14, 0 })

    local match = patterns.find(0, test_spec, { count = 1 })

    eq(match, nil)
end

T["patterns/find_at_cursor multiline"] = new_set()

T["patterns/find_at_cursor multiline"]["finds a match in middle of text on first line and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 8 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 8 })
end

T["patterns/find_at_cursor multiline"]["finds a match in middle of text on second line and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 4 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 4 })
end

T["patterns/find_at_cursor multiline"]["finds a match at cursor at beginning of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 0 })
end

T["patterns/find_at_cursor multiline"]["finds a match at cursor at end of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 17 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, match)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 17 })
end

T["patterns/find_at_cursor multiline"]["finds no match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 5 })

    local match = patterns.find_at_cursor(0, test_spec)

    eq(match, nil)
end

T["patterns/find_in_lines multiline"] = new_set()

T["patterns/find_in_lines multiline"]["finds a match in some lines with no offset"] = function()
    local lnum = patterns.find_in_lines(rustc_test_lines, test_spec)

    eq(lnum, 2)
end

T["patterns/find_in_lines multiline"]["finds a match in some lines with offset"] = function()
    local lnum = patterns.find_in_lines(rustc_test_lines, test_spec, 6)

    eq(lnum, 11)
end

T["patterns/find_in_lines multiline"]["finds no match"] = function()
end

T["patterns/find_at_line multiline"] = new_set()

T["patterns/find_at_line multiline"]["finds a pattern at a line with no offset"] = function()
    local match = patterns.find_at_line(rustc_test_lines, test_spec, 3)

    eq(match, match1)
end

T["patterns/find_at_line multiline"]["finds a pattern at a line with offset"] = function()
    local match = patterns.find_at_line(rustc_test_lines, test_spec, 12)

    eq(match, match2)
end

T["patterns/parse_subgroup multiline"] = new_set()

return T
