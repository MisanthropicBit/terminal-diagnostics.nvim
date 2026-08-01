local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local eslint_stylish_command_spec =
    require("terminal-diagnostics.command_specs.eslint-stylish")

local test_matcher = eslint_stylish_command_spec:matcher()
local error_spec = test_matcher:specs()[1]

local match = {
    range = {
        from = {
            col = 0,
            lnum = 2,
        },
        to = {
            col = 77,
            lnum = 3,
        },
    },
    submatches = {
        "/Users/terminal-diagnostics/test-files/target-files/foo.js",
        "1",
        "10",
        "error",
        "'addOne' is defined but never used           ",
        "no-unused-vars",
    },
    text =
    "/Users/terminal-diagnostics/test-files/target-files/foo.js\n  1:10  error    'addOne' is defined but never used            no-unused-vars",
    spec = error_spec,
}

local T = new_set({
    hooks = {
        pre_once = function()
            vim.cmd.edit("test-files/eslint-stylish.txt")
        end,
    },
})

T["HeaderMatcher"] = new_set()
T["HeaderMatcher"]["match"] = new_set()

T["HeaderMatcher"]["match"]["finds a match on header with info"] = function()
    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["HeaderMatcher"]["match"]["finds a match and uses last match position"] = function()
    eq(test_matcher:find_match_start({ buffer = 0, lnum = 1, col = 0, count = 1 }), match)
    vim.api.nvim_win_set_cursor(0, { 4, 2 }) -- FIX: Should only work on a match

    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["HeaderMatcher"]["match"]["finds no match"] = function()
    vim.api.nvim_win_set_cursor(0, { 13, 0 })

    local match_result = test_matcher:match({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, {})
end

T["HeaderMatcher"]["match_at_cursor"] = new_set()

T["HeaderMatcher"]["match_at_cursor"]["finds a match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 22 })

    local match_result =
        test_matcher:match_at_cursor({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, { match })
end

T["HeaderMatcher"]["match_at_cursor"]["does not find a match at cursor"] = function()
    vim.api.nvim_win_set_cursor(0, { 13, 4 })

    local match_result =
        test_matcher:match_at_cursor({ buffer = 0, lnum = 1, col = 0, count = 1 })

    eq(match_result, {})
end

T["HeaderMatcher"]["extract_values"] = new_set()

-- T["HeaderMatcher"]["extract_values"]["extracts values"] = function()
--     vim.api.nvim_win_set_cursor(0, { 1, 0 })
--
--     local matches = test_matcher:match({ buffer = 0, count = 1 })
--     vim.print(vim.inspect(matches))
--     local values = test_matcher:extract_values(matches)
--
--     eq(values, {
--         code = "no-unused-vars",
--         col = 10,
--         lnum = 1,
--         message = "'addOne' is defined but never used           ",
--         paths = { "./test-files/target-files/foo.js" },
--         severity = 1,
--     })
-- end

return T
