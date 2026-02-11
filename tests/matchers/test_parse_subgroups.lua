local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local parse_subgroup = require("lua.terminal-diagnostics.matchers.parse_subgroups")

-- TODO: Support and test multiline regexes

-- TODO: Expose so we do not redefine them in tests
local tsc_spec = {
    name = "tsc",
    regex =
    "\\v^([^[:space:]]*)[\\(:](\\d+)[,:](\\d+)%(\\):\\s+|\\s+-\\s+)(error|warning|info)\\s+TS(\\d+)\\s*:\\s*(.*)$",
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local tsc_match =
"main.ts:6:5 - error TS2322: Type 'null' is not assignable to type 'Person'."

local jest_spec = {
    regex = [[\vat \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "relative",
    lnum = 2,
    col = 3,
}

local jest_match = "at Object.toEqual (src/fail-throws-synchronous.test.js:10:19)"

local T = new_set()

T["matchers/parse_subgroup/parses tsc subgroups"] = function()
    local result = parse_subgroup.parse(tsc_match, tsc_spec)

    eq(result, {
        path = { start_col = 1, end_col = 7 },
        lnum = { start_col = 9, end_col = 9 },
        col = { start_col = 11, end_col = 11 },
        severity = { start_col = 15, end_col = 19 },
        code = { start_col = 23, end_col = 26 },
        message = { start_col = 29, end_col = 75 },
    })
end

T["matchers/parse_subgroup/parses jest subgroups"] = function()
    local result = parse_subgroup.parse(jest_match, jest_spec)

    eq(result, {
        path = { start_col = 20, end_col = 54 },
        lnum = { start_col = 56, end_col = 57 },
        col = { start_col = 59, end_col = 60 },
    })
end

return T
