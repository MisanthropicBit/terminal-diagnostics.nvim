local new_set = MiniTest.new_set
local eq, neq = MiniTest.expect.equality, MiniTest.expect.no_equality

local CommandSpec = require("terminal-diagnostics.command_spec")
local command_spec = require("terminal-diagnostics.builtins.rustc")

local matcher = command_spec:matcher()
local match_spec = matcher:specs()[1]

local parser = command_spec:parser()

local match1 = {
    {
        match = {
            from = {
                col = 0,
                lnum = 2,
            },
            spec = match_spec,
            submatches = { "error", "E0000", "main error message", "file.rs", "14", "5" },
            text = "error[E0000]: main error message\n  --> file.rs:14:5",
            to = {
                col = 18,
                lnum = 3,
            },
        },
        spec = match_spec,
    },
}

local match2 = {
    {
        match = {
            from = {
                col = 0,
                lnum = 11,
            },
            spec = match_spec,
            submatches = {
                "note",
                "",
                "sub-diagnostic message for `.span_note`",
                "file.rs",
                "10",
                "4",
            },
            text = "note: sub-diagnostic message for `.span_note`\n  --> file.rs:10:4",
            to = {
                col = 18,
                lnum = 12,
            },
        },
        spec = match_spec,
    },
}

local expected_parse_results = {
    {
        buffer = 0,
        context = {
            lines = {
                "   |",
                "14 | <code>",
                "   | -^^^^- secondary label",
                "   |  |",
                "   |  primary label",
                "   |",
                "   = note: note without a `Span`, created with `.note`",
            },
            range = {
                end_ = {
                    col = 54,
                    lnum = 10,
                },
                start = {
                    col = 0,
                    lnum = 4,
                },
            },
        },
        kind = "build",
        matches = {
            {
                from = {
                    col = 0,
                    lnum = 2,
                },
                spec = match_spec,
                submatches = {
                    "error",
                    "E0000",
                    "main error message",
                    "file.rs",
                    "14",
                    "5",
                },
                text = "error[E0000]: main error message\n  --> file.rs:14:5",
                to = {
                    col = 18,
                    lnum = 3,
                },
            },
        },
        range = {
            end_ = {
                col = 18,
                lnum = 3,
            },
            start = {
                col = 0,
                lnum = 2,
            },
        },
        source = "rustc",
        values = {
            code = "E0000",
            col = 5,
            lnum = 14,
            message = "main error message",
            paths = {
                "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/file.rs",
            },
            severity = "error",
        },
    },
    {
        buffer = 0,
        context = {
            lines = {
                "   |",
                "10 | more code",
                "   |      ^^^^",
            },
            range = {
                end_ = {
                    col = 14,
                    lnum = 15,
                },
                start = {
                    col = 0,
                    lnum = 13,
                },
            },
        },
        kind = "build",
        matches = {
            {
                from = {
                    col = 0,
                    lnum = 11,
                },
                spec = match_spec,
                submatches = {
                    "note",
                    "",
                    "sub-diagnostic message for `.span_note`",
                    "file.rs",
                    "10",
                    "4",
                },
                text = "note: sub-diagnostic message for `.span_note`\n  --> file.rs:10:4",
                to = {
                    col = 18,
                    lnum = 12,
                },
            },
        },
        range = {
            end_ = {
                col = 18,
                lnum = 12,
            },
            start = {
                col = 0,
                lnum = 11,
            },
        },
        source = "rustc",
        values = {
            code = "",
            col = 4,
            lnum = 10,
            message = "sub-diagnostic message for `.span_note`",
            paths = {
                "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/file.rs",
            },
            severity = "info",
        },
    },
}

---@type string[]
local test_lines = {}

local T = new_set({
    hooks = {
        pre_once = function()
            test_lines = vim.fn.readfile("test-files/rustc.txt")
        end,
    },
})

T["builtins.rustc"] = new_set()
T["builtins.rustc"]["CommandSpec"] = new_set()
T["builtins.rustc"]["CommandSpec"]["matcher"] = new_set()
T["builtins.rustc"]["CommandSpec"]["parser"] = new_set()

T["builtins.rustc"]["CommandSpec"]["self"] = function()
    eq(command_spec:name(), "rustc")
    eq(command_spec:kind(), CommandSpec.CommandKind.Build)
    neq(command_spec:matcher(), nil)
    neq(command_spec:parser(), nil)
    eq(command_spec:parser():has_context(), true)
end

T["builtins.rustc"]["CommandSpec"]["matcher"]["specs"] = function()
    eq(#matcher:specs(), 1)
end

T["builtins.rustc"]["CommandSpec"]["matcher"]["match"] = function()
    vim.cmd.edit("test-files/rustc.txt")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:match({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 15, 0 })
    eq(matcher:match({ buffer = 0 }), {})
end

T["builtins.rustc"]["CommandSpec"]["matcher"]["find_match_start"] = function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match1[1].match)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1].match)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1].match)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1].match)

    vim.api.nvim_win_set_cursor(0, { 15, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), nil)
end

T["builtins.rustc"]["CommandSpec"]["matcher"]["match_at_cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 6, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 10, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})
end

T["builtins.rustc"]["CommandSpec"]["parser"]["parse"] = function()
    local parse_results = parser:parse(test_lines, { buffer = 0 })

    eq(parse_results, expected_parse_results)
end

T["builtins.rustc"]["CommandSpec"]["parser"]["parse_buffer"] = function()
    local parse_results = parser:parse_buffer(0, {})

    eq(parse_results, expected_parse_results)
end

return T
