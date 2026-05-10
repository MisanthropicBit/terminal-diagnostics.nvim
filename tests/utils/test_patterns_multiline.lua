local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local utils = require("terminal-diagnostics.utils")

vim.fn.matchstrlist({ "./test-files/target-files/foo.js\n  1:10  error    'addOne' is defined but never used            no-unused-vars" } , [=[\v\zs^(%([a-zA-Z]:)*[./\\]+.{-})\ze\n\s+(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]=], { submatches = true })

vim.fn.searchpos([=[\v\zs^(%([a-zA-Z]:)*[./\\]+.{-})\ze\n\s+(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]=], "cneW")

---@type terminal-diagnostics.MatchSpec
local multiline_spec = {
    pattern = [=[\v^(%([a-zA-Z]:)*[./\\]+.{-})\n\s+(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]=],
    path = 1,
    path_kind = "absolute",
    multiline = true,
}

local positive_match = {
    text = { "./test-files/target-files/foo.js\n  1:10  error    'addOne' is defined but never used            no-unused-vars" },
    submatches = { "./test-files/target-files/foo.js", "1", "10", "error", "'addOne' is defined but never used           ", "no-unused-vars", "", "", "" },
    from = {
        lnum = 3,
        col = 1,
    },
    to = {
        lnum = 4,
        col = 77,
    },
    spec = multiline_spec,
}

local T = new_set({
    hooks = {
        pre_case = function()
            vim.cmd.edit("test-files/eslint-stylish.txt")
        end,
    },
})

T["utils"] = new_set()
T["utils/patterns/find multiline"] = new_set()
T["utils/patterns/find_at_cursor multiline"] = new_set()

-- T["utils/patterns/find multiline"]["finds a match and keeps cursor position"] = function()
--     vim.api.nvim_win_set_cursor(0, { 3, 3 }) -- On the 's' of 'tsc'
--
--     local match = utils.patterns.find(0, spec, 1)
--
--     eq(match, positive_match1)
--     eq(vim.api.nvim_win_get_cursor(0), { 3, 3 })
-- end

-- T["utils/patterns/find"]["finds no match at the beginning of pattern"] = function()
--     vim.api.nvim_win_set_cursor(0, { 4, 1 })
--
--     local match = utils.patterns.find(0, spec, 1)
--
--     eq(match, positive_match2)
-- end

-- T["utils/patterns/find"]["finds no match at the end of pattern"] = function()
--     vim.api.nvim_win_set_cursor(0, { 4, 75 })
--
--     local match = utils.patterns.find(0, spec, 1)
--
--     eq(match, positive_match2)
-- end

-- T["utils/patterns/find"]["finds no match"] = function()
--     vim.api.nvim_win_set_cursor(0, { 10, 0 })
--
--     local match = utils.patterns.find(0, spec, 1)
--
--     eq(match, nil)
-- end

T["utils/patterns/find_at_cursor multiline"]["finds a match at cursor in middle of text and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 16 }) -- On the 'g' in 'target'

    local match = utils.patterns.find_at_cursor(0, multiline_spec)

    eq(match, positive_match)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 16 })
end

T["utils/patterns/find_at_cursor multiline"]["finds a match at cursor at beginning of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 0 })

    local match = utils.patterns.find_at_cursor(0, multiline_spec)

    eq(match, positive_match)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 0 })
end

T["utils/patterns/find_at_cursor multiline"]["finds a match at cursor at end of pattern and keeps cursor position"] = function()
    vim.api.nvim_win_set_cursor(0, { 3, 31 })

    local match = utils.patterns.find_at_cursor(0, multiline_spec)

    eq(match, positive_match)
    eq(vim.api.nvim_win_get_cursor(0), { 3, 31 })
end

T["utils/patterns/find_at_cursor multiline"]["does not find a match at cursor at end of pattern on last line"] = function()
    vim.api.nvim_win_set_cursor(0, { 4, 76 })

    local match = utils.patterns.find_at_cursor(0, multiline_spec)

    eq(match, nil)
    eq(vim.api.nvim_win_get_cursor(0), { 4, 76 })
end

-- T["utils/patterns/find_at_cursor"]["finds no match at cursor"] = function()
--     vim.api.nvim_win_set_cursor(0, { 5, 0 })
--
--     local match = utils.patterns.find_at_cursor(0, spec)
--
--     eq(match, nil)
-- end

return T
