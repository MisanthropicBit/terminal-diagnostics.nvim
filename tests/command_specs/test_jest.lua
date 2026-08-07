local new_set = MiniTest.new_set
local eq, neq = MiniTest.expect.equality, MiniTest.expect.no_equality

local CommandSpec = require("terminal-diagnostics.command_spec")
local command_spec = require("terminal-diagnostics.command_specs.jest")

local matcher = command_spec:matcher()
local header_spec = matcher:specs()[1]
local error_spec = matcher:specs()[2]
local parser = command_spec:parser()

local match1 = {
    {
        range = {
            from = {
                col = 0,
                lnum = 2,
            },
            to = {
                col = 36,
                lnum = 2,
            },
        },
        spec = header_spec,
        submatches = { "FAIL", "test-files/target-files/test.ts" },
        text = "FAIL test-files/target-files/test.ts",
    }
}

local match2 = {
    {
        range = {
            from = {
                col = 0,
                lnum = 20,
            },
            to = {
                col = 63,
                lnum = 20,
            },
        },
        spec = error_spec,
        submatches = {
            "test-files/target-files/test.ts",
            "10",
            "19",
        },
        text = "      at Object.toEqual (test-files/target-files/test.ts:10:19)",
    },
}

local match3 = {
    {
        range = {
            from = {
                col = 0,
                lnum = 21,
            },
            to = {
                col = 62,
                lnum = 21,
            },
        },
        spec = error_spec,
        submatches = {
            "test-files/target-files/test.ts",
            "12",
            "1",
        },
        text = "      at Object.toEqual (test-files/target-files/test.ts:12:1)",
    },
}

local match4 = {
    {
        range = {
            from = {
                col = 0,
                lnum = 22,
            },
            to = {
                col = 62,
                lnum = 22,
            },
        },
        spec = error_spec,
        submatches = {
            "test-files/target-files/test.ts",
            "14",
            "3",
        },
        text = "      at Object.toEqual (test-files/target-files/test.ts:14:3)",
    },
}

local context_lines = {
    "  ✕ should throw if passed true (9ms)",
    "",
    "  ● should throw if passed true",
    "",
    "    expect(received).toEqual(expected) // deep equality",
    "",
    "    Expected: [Error: shouldThrow was true]",
    "    Received: [Error: didn't throw]",
    "",
    '       8 |     throw new Error("didn\'t throw");',
    "       9 |   } catch (error) {",
    "    > 10 |     expect(error).toEqual(new Error('shouldThrow was true'));",
    "         |                   ^",
    "      11 |   }",
    "      12 | });",
    "      13 |",
    "",
}

local expected_parse_results = {
    {
        buffer = 0,
        command_spec = command_spec,
        matches = {
            {
                range = {
                    from = {
                        col = 0,
                        lnum = 2,
                    },
                    to = {
                        col = 36,
                        lnum = 2,
                    },
                },
                spec = header_spec,
                submatches = { "FAIL", "test-files/target-files/test.ts" },
                text = "FAIL test-files/target-files/test.ts",
            },
        },
        range = {
            from = {
                col = 0,
                lnum = 2,
            },
            to = {
                col = 36,
                lnum = 2,
            },
        },
        -- values = {
        --     paths = { "test-files/target-files/test.ts" },
        --     severity = "ERROR",
        -- },
        context = {
            lines = context_lines,
            range = {
                from = {
                    col = 0,
                    lnum = 3,
                },
                to = {
                    col = 0,
                    lnum = 19,
                },
            },
        },
    },
    {
        buffer = 0,
        command_spec = command_spec,
        matches = {
            {
                range = {
                    from = {
                        col = 0,
                        lnum = 20,
                    },
                    to = {
                        col = 63,
                        lnum = 20,
                    },
                },
                spec = error_spec,
                submatches = {
                    "test-files/target-files/test.ts",
                    "10",
                    "19",
                },
                text = "      at Object.toEqual (test-files/target-files/test.ts:10:19)",
            },
        },
        range = {
            from = {
                col = 0,
                lnum = 20,
            },
            to = {
                col = 63,
                lnum = 20,
            },
        },
        values = {
            col = 19,
            lnum = 10,
            paths = { "test-files/target-files/test.ts" },
            severity = "ERROR",
        },
    },
    {
        buffer = 0,
        command_spec = command_spec,
        matches = {
            {
                range = {
                    from = {
                        col = 0,
                        lnum = 21,
                    },
                    to = {
                        col = 62,
                        lnum = 21,
                    },
                },
                spec = error_spec,
                submatches = {
                    "test-files/target-files/test.ts",
                    "12",
                    "1",
                },
                text = "      at Object.toEqual (test-files/target-files/test.ts:12:1)",
            },
        },
        range = {
            from = {
                col = 0,
                lnum = 21,
            },
            to = {
                col = 62,
                lnum = 21,
            },
        },
        values = {
            col = 1,
            lnum = 12,
            paths = { "test-files/target-files/test.ts" },
            severity = "ERROR",
        },
    },
    {
        buffer = 0,
        command_spec = command_spec,
        matches = {
            {
                range = {
                    from = {
                        col = 0,
                        lnum = 22,
                    },
                    to = {
                        col = 62,
                        lnum = 22,
                    },
                },
                spec = error_spec,
                submatches = {
                    "test-files/target-files/test.ts",
                    "14",
                    "3",
                },
                text = "      at Object.toEqual (test-files/target-files/test.ts:14:3)",
            },
        },
        range = {
            from = {
                col = 0,
                lnum = 22,
            },
            to = {
                col = 62,
                lnum = 22,
            },
        },
        values = {
            col = 3,
            lnum = 14,
            paths = { "test-files/target-files/test.ts" },
            severity = "ERROR",
        },
    },
}

---@type string[]
local test_lines = {}

local T = new_set({
    hooks = {
        pre_once = function()
            test_lines = vim.fn.readfile("test-files/jest.txt")
        end,
    },
})

T["command_specs.jest"] = new_set()
T["command_specs.jest"]["CommandSpec"] = new_set()
T["command_specs.jest"]["CommandSpec"]["matcher"] = new_set()
T["command_specs.jest"]["CommandSpec"]["parser"] = new_set()

T["command_specs.jest"]["CommandSpec"]["self"] = function()
    eq(command_spec:name(), "jest")
    eq(command_spec:kind(), CommandSpec.CommandKind.Test)
    neq(command_spec:matcher(), nil)
    neq(command_spec:parser(), nil)
    eq(command_spec:parser():has_context(), true)
end

T["command_specs.jest"]["CommandSpec"]["matcher"]["specs"] = function()
    eq(#matcher:specs(), 2)
end

T["command_specs.jest"]["CommandSpec"]["matcher"]["match"] = function()
    vim.cmd.edit("test-files/jest.txt")

    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:match({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match({ buffer = 0 }), match2)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match({ buffer = 0 }), { match2[1], match1[1] })

    vim.api.nvim_win_set_cursor(0, { 21, 0 })
    eq(matcher:match({ buffer = 0 }), { match3[1], match1[1] })

    vim.api.nvim_win_set_cursor(0, { 22, 0 })
    eq(matcher:match({ buffer = 0 }), { match4[1], match1[1] })

    vim.api.nvim_win_set_cursor(0, { 23, 0 })
    eq(matcher:match({ buffer = 0 }), {})
end

T["command_specs.jest"]["CommandSpec"]["matcher"]["find_match_start"] = function()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match1[1])

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1])

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match2[1])

    vim.api.nvim_win_set_cursor(0, { 21, 29 })
    eq(matcher:find_match_start({ buffer = 0 }), match3[1])

    vim.api.nvim_win_set_cursor(0, { 22, 0 })
    eq(matcher:find_match_start({ buffer = 0 }), match4[1])

    -- FIX:
    -- vim.api.nvim_win_set_cursor(0, { 23, 0 })
    -- eq(matcher:find_match_start({ buffer = 0 }), {})
end

T["command_specs.jest"]["CommandSpec"]["matcher"]["match_at_cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 3, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), match1)

    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})

    vim.api.nvim_win_set_cursor(0, { 21, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), { match1[1], match2[1] })

    vim.api.nvim_win_set_cursor(0, { 22, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), { match1[1], match3[1] })

    vim.api.nvim_win_set_cursor(0, { 23, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), { match1[1], match4[1] })

    vim.api.nvim_win_set_cursor(0, { 25, 0 })
    eq(matcher:match_at_cursor({ buffer = 0 }), {})
end

T["command_specs.jest"]["CommandSpec"]["parser"]["parse"] = function()
    local parse_results = parser:parse(test_lines, { buffer = 0, extract = true })

    eq(parse_results, expected_parse_results)
end

T["command_specs.jest"]["CommandSpec"]["parser"]["parse_buffer"] = function()
    local parse_results = parser:parse_buffer(0, { extract = true })

    eq(parse_results, expected_parse_results)
end

return T
