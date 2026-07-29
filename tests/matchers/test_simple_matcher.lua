local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality
local err = MiniTest.expect.error

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
        end,
    },
})

T["SimpleMatcher"] = new_set()
T["SimpleMatcher"]["match"] = new_set()

T["SimpleMatcher"]["match"]["finds a match"] = function()
    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["SimpleMatcher"]["match"]["finds a match and uses last match position"] = function()
    eq(test_matcher:find_match_start({ buffer = 0, lnum = 1, col = 0, count = 1 }), match)
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["SimpleMatcher"]["match"]["finds no match"] = function()
    vim.api.nvim_win_set_cursor(0, { 13, 0 })

    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, {})
end

T["SimpleMatcher"]["match_at_cursor"] = new_set()

T["SimpleMatcher"]["match_at_cursor"]["finds a match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 })

    local match_result =
        test_matcher:match_at_cursor({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["SimpleMatcher"]["match_at_cursor"]["does not find a match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 6, 10 })

    local match_result =
        test_matcher:match_at_cursor({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, {})
end

T["SimpleMatcher"]["extract_values"] = new_set()

T["SimpleMatcher"]["extract_values"]["extracs values"] = function()
    local values = test_matcher:extract_values({ match })

    eq(values, {
        code = "2322",
        col = 26,
        lnum = 6,
        message = "Type 'null' is not assignable to type 'Person'.",
        paths = {
            "/Users/hyrule/projects/nvim/terminal-diagnostics.nvim/test-files/target-files/main.ts",
        },
        severity = "ERROR",
    })
end

T["SimpleMatcher"]["extract_values"]["fails if zero results"] = function()
    err(function()
        test_matcher:extract_values({})
    end, "SimpleMatcher:extract_values expected only one result but got '0'")
end

T["SimpleMatcher"]["extract_values"]["fails if too many results"] = function()
    err(function()
        test_matcher:extract_values({ match, match })
    end, "SimpleMatcher:extract_values expected only one result but got '2'")
end

return T
