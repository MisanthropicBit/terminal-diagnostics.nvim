local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local tsc_command_spec = require("terminal-diagnostics.command_specs.tsc")

local test_parser = tsc_command_spec:parser()
local test_spec = tsc_command_spec:matcher():specs()[1]

local expected_parse_results = {
    {
        command_spec = tsc_command_spec,
        buffer = 0,
        range = {
            start = {
                lnum = 3,
                col = 0,
            },
            end_ = {
                lnum = 3,
                col = 76,
            },
        },
        context = {
            lines = {
                "",
                "6     return null;",
                "      ~~~~~~~~~~~~",
                "",
            },
            range = {
                start = {
                    lnum = 4,
                    col = 0,
                },
                end_ = {
                    lnum = 7,
                    col = 0,
                },
            },
        },
        matches = {
            {
                submatches = {
                    "main.ts",
                    "6",
                    "26",
                    "error",
                    "2322",
                    "Type 'null' is not assignable to type 'Person'.",
                },
                range = {
                    from = {
                        lnum = 3,
                        col = 0,
                    },
                    to = {
                        lnum = 3,
                        col = 76,
                    },
                },
                text = "main.ts:6:26 - error TS2322: Type 'null' is not assignable to type 'Person'.",
                spec = test_spec,
            },
        },
        values = {
            code = "2322",
            col = 26,
            lnum = 6,
            message = "Type 'null' is not assignable to type 'Person'.",
            paths = {
                "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/main.ts",
            },
            severity = "ERROR",
        },
    },
    {
        command_spec = tsc_command_spec,
        buffer = 0,
        range = {
            start = {
                lnum = 8,
                col = 0,
            },
            end_ = {
                lnum = 8,
                col = 81,
            },
        },
        context = {
            lines = {
                "",
                "6     return undefined;",
                "      ~~~~~~~~~~~~~~~~~",
                "",
            },
            range = {
                start = {
                    lnum = 9,
                    col = 0,
                },
                end_ = {
                    lnum = 13,
                    col = 0,
                },
            },
        },
        matches = {
            {
                submatches = {
                    "main.ts",
                    "7",
                    "27",
                    "error",
                    "2322",
                    "Type 'undefined' is not assignable to type 'Person'.",
                },
                range = {
                    from = {
                        lnum = 8,
                        col = 0,
                    },
                    to = {
                        lnum = 8,
                        col = 81,
                    },
                },
                text = "main.ts:7:27 - error TS2322: Type 'undefined' is not assignable to type 'Person'.",
                spec = test_spec,
            },
        },
        values = {
            code = "2322",
            col = 27,
            lnum = 7,
            message = "Type 'undefined' is not assignable to type 'Person'.",
            paths = {
                "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/main.ts",
            },
            severity = "ERROR",
        },
    },
}

---@type string[]
local test_lines = {}

local T = new_set({
    hooks = {
        pre_once = function()
            test_lines = vim.fn.readfile("test-files/tsc.txt")
        end,
    },
})

T["SimpleParser"] = new_set()
T["SimpleParser"]["parse"] = new_set()

T["SimpleParser"]["parse"]["parses lines"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, extract = true })

    eq(parse_results, expected_parse_results)
end

T["SimpleParser"]["parse"]["parses lines with offset"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, offset = 5, extract = true })

    eq(parse_results, { expected_parse_results[2] })
end

T["SimpleParser"]["parse"]["parses lines with offset with no results"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, offset = 10, extract = true })

    eq(parse_results, {})
end

T["SimpleParser"]["parse"]["parses lines with count"] = function()
    local parse_results = test_parser:parse(test_lines, { buffer = 0, count = 1, extract = true })

    eq(parse_results, { expected_parse_results[1] })
end

T["SimpleParser"]["parse"]["parses nothing"] = function()
    local parse_results = test_parser:parse({}, { buffer = 0, extract = true })

    eq(parse_results, {})
end

T["SimpleParser"]["parse_buffer"] = new_set()

T["SimpleParser"]["parse_buffer"]["parses a buffer"] = function()
    vim.cmd.edit("test-files/tsc.txt")

    local parse_results = test_parser:parse_buffer(0, {})

    eq(parse_results, expected_parse_results)
end

return T
