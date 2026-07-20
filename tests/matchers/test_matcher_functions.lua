local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local matchers = require("terminal-diagnostics.matchers")
local test_spec = require("terminal-diagnostics.builtins.tsc"):matcher():specs()[1]

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

local T = new_set()

T["matchers"] = new_set()

T["matchers"]["extract_from_match"] = function()
    local result = matchers.extract_from_match(match)

    eq(result, {
        name = "tsc",
        paths = { vim.fs.abspath(vim.fs.normalize("../test-files/target-files/main.ts")) },
        lnum = tonumber(match.submatches[2]),
        col = tonumber(match.submatches[3]),
        severity = 1,
        code = match.submatches[5],
        message = match.submatches[6],
    })
end

T["matchers"]["spec_has_info"] = function()
    eq(matchers.spec_has_info(test_spec), true)
    eq(matchers.spec_has_info({ pattern = test_spec.pattern }), false)
end

T["matchers"]["match_spec_keys"] = function()
    eq(
        matchers.match_spec_keys(),
        { "path", "lnum", "col", "severity", "code", "message" }
    )
end

return T
