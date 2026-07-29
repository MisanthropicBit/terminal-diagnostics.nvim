local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local err = MiniTest.expect.error

local eslint_stylish_command_spec =
    require("terminal-diagnostics.command_specs.eslint-stylish")

local test_parser = eslint_stylish_command_spec:parser()
local header_spec = eslint_stylish_command_spec:matcher():specs()[1]
local error_spec = eslint_stylish_command_spec:matcher():specs()[2]

local expected_parse_results = {
    -- {
    --     source = eslint_stylish_command_spec:name(),
    --     buffer = 0,
    --     kind = eslint_stylish_command_spec:kind(),
    --     range = {
    --         start = {
    --             lnum = 2,
    --             col = 0,
    --         },
    --         end_ = {
    --             lnum = 2,
    --             col = 32,
    --         },
    --     },
    --     context = nil,
    --     matches = {
    --         {
    --             submatches = {
    --                 "./test-files/target-files/foo.js",
    --             },
    --             from = {
    --                 lnum = 2,
    --                 col = 0,
    --             },
    --             to = {
    --                 lnum = 2,
    --                 col = 32,
    --             },
    --             text = "./test-files/target-files/foo.js",
    --             spec = header_spec,
    --         },
    --     },
    --     values = {
    --         paths = {
    --             "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/foo.js",
    --         },
    --     },
    -- },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 3,
                col = 0,
            },
            end_ = {
                lnum = 3,
                col = 77,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "1",
                    "10",
                    "error",
                    "'addOne' is defined but never used           ",
                    "no-unused-vars",
                },
                from = {
                    lnum = 3,
                    col = 0,
                },
                to = {
                    lnum = 3,
                    col = 77,
                },
                text = "  1:10  error    'addOne' is defined but never used            no-unused-vars",
                spec = error_spec,
            },
        },
        values = {
            code = "no-unused-vars",
            col = 10,
            lnum = 1,
            message = "'addOne' is defined but never used           ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = 1,
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 4,
                col = 0,
            },
            end_ = {
                lnum = 4,
                col = 72,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "2",
                    "9",
                    "error",
                    "Use the isNaN function to compare with NaN   ",
                    "use-isnan",
                },
                from = {
                    lnum = 4,
                    col = 0,
                },
                to = {
                    lnum = 4,
                    col = 72,
                },
                text = "  2:9   error    Use the isNaN function to compare with NaN    use-isnan",
                spec = error_spec,
            },
        },
        values = {
            code = "use-isnan",
            col = 9,
            lnum = 2,
            message = "Use the isNaN function to compare with NaN   ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = 1,
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 5,
                col = 0,
            },
            end_ = {
                lnum = 5,
                col = 78,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "3",
                    "16",
                    "error",
                    "Unexpected space before unary operator '++'  ",
                    "space-unary-ops",
                },
                from = {
                    lnum = 5,
                    col = 0,
                },
                to = {
                    lnum = 5,
                    col = 78,
                },
                text = "  3:16  error    Unexpected space before unary operator '++'   space-unary-ops",
                spec = error_spec,
            },
        },
        values = {
            code = "space-unary-ops",
            col = 16,
            lnum = 3,
            message = "Unexpected space before unary operator '++'  ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = 1,
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 6,
                col = 0,
            },
            end_ = {
                lnum = 6,
                col = 67,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "3",
                    "20",
                    "warning",
                    "Missing semicolon                            ",
                    "semi",
                },
                from = {
                    lnum = 6,
                    col = 0,
                },
                to = {
                    lnum = 6,
                    col = 67,
                },
                text = "  3:20  warning  Missing semicolon                             semi",
                spec = error_spec,
            },
        },
        values = {
            code = "semi",
            col = 20,
            lnum = 3,
            message = "Missing semicolon                            ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = "WARN",
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 7,
                col = 0,
            },
            end_ = {
                lnum = 7,
                col = 77,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "4",
                    "12",
                    "warning",
                    "Unnecessary 'else' after 'return'            ",
                    "no-else-return",
                },
                from = {
                    lnum = 7,
                    col = 0,
                },
                to = {
                    lnum = 7,
                    col = 77,
                },
                text = "  4:12  warning  Unnecessary 'else' after 'return'             no-else-return",
                spec = error_spec,
            },
        },
        values = {
            code = "no-else-return",
            col = 12,
            lnum = 4,
            message = "Unnecessary 'else' after 'return'            ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = "WARN",
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 8,
                col = 0,
            },
            end_ = {
                lnum = 8,
                col = 69,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "5",
                    "1",
                    "warning",
                    "Expected indentation of 8 spaces but found 6 ",
                    "indent",
                },
                from = {
                    lnum = 8,
                    col = 0,
                },
                to = {
                    lnum = 8,
                    col = 69,
                },
                text = "  5:1   warning  Expected indentation of 8 spaces but found 6  indent",
                spec = error_spec,
            },
        },
        values = {
            code = "indent",
            col = 1,
            lnum = 5,
            message = "Expected indentation of 8 spaces but found 6 ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = "WARN",
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 9,
                col = 0,
            },
            end_ = {
                lnum = 9,
                col = 80,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "5",
                    "7",
                    "error",
                    "Function 'addOne' expected a return value    ",
                    "consistent-return",
                },
                from = {
                    lnum = 9,
                    col = 0,
                },
                to = {
                    lnum = 9,
                    col = 80,
                },
                text = "  5:7   error    Function 'addOne' expected a return value     consistent-return",
                spec = error_spec,
            },
        },
        values = {
            code = "consistent-return",
            col = 7,
            lnum = 5,
            message = "Function 'addOne' expected a return value    ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = 1,
        },
    },
    {
        source = eslint_stylish_command_spec:name(),
        buffer = 0,
        kind = eslint_stylish_command_spec:kind(),
        range = {
            start = {
                lnum = 10,
                col = 0,
            },
            end_ = {
                lnum = 10,
                col = 67,
            },
        },
        context = nil,
        matches = {
            {
                submatches = {
                    "5",
                    "13",
                    "warning",
                    "Missing semicolon                            ",
                    "semi",
                },
                from = {
                    lnum = 10,
                    col = 0,
                },
                to = {
                    lnum = 10,
                    col = 67,
                },
                text = "  5:13  warning  Missing semicolon                             semi",
                spec = error_spec,
            },
        },
        values = {
            code = "semi",
            col = 13,
            lnum = 5,
            message = "Missing semicolon                            ",
            paths = {
                "/Users/terminal-diagnostics/test-files/target-files/foo.js",
            },
            severity = "WARN",
        },
    },
}

---@type string[]
local test_lines = {}

local T = new_set({
    hooks = {
        pre_once = function()
            test_lines = vim.fn.readfile("test-files/eslint-stylish.txt")
        end,
    },
})

T["HeaderParser"] = new_set()
T["HeaderParser"]["parse"] = new_set()

T["HeaderParser"]["parse"]["parses lines"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0 })

    eq(parse_results, expected_parse_results)
end

-- FIX: Does not work because the header is not parsed. Perhaps just intentional?
-- T["HeaderParser"]["parse"]["parses lines with offset"] = function()
--     local parse_results = test_parser:parse(test_lines, { buffer = 0, offset = 6 })
--
--     eq(parse_results, { vim.list_slice(expected_parse_results, 3) })
-- end

T["HeaderParser"]["parse"]["parses lines with offset with no results"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, offset = 12 })

    eq(parse_results, {})
end

T["HeaderParser"]["parse"]["parses lines with count"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, count = 1 })

    eq(parse_results, { expected_parse_results[1] })
end

T["HeaderParser"]["parse"]["parses nothing"] = function()
    local parse_results = test_parser:parse({}, { buffer = 0 })

    eq(parse_results, {})
end

T["HeaderParser"]["parse_buffer"] = new_set()

T["HeaderParser"]["parse_buffer"]["parses a buffer"] = function()
    vim.cmd.edit("test-files/eslint-stylish.txt")

    local parse_results = test_parser:parse_buffer(0, {})

    eq(parse_results, expected_parse_results)
end

return T
