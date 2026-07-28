local new_set = MiniTest.new_set
local eq, neq, has_error =
    MiniTest.expect.equality, MiniTest.expect.no_equality, MiniTest.expect.error

local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")

local matcher = SimpleMatcher.new({ specs = {} })
local T = new_set()

T["CommandSpec"] = new_set()

T["CommandSpec"]["creates a new command spec with default parser"] = function()
    local command_spec = CommandSpec.new("test", CommandSpec.CommandKind.Build, matcher)

    eq(command_spec:name(), "test")
    eq(command_spec:kind(), CommandSpec.CommandKind.Build)
    eq(command_spec:matcher(), matcher)
    neq(command_spec:parser(), nil)
end

T["CommandSpec"]["fails to validate name"] = function()
    has_error(function()
        ---@diagnostic disable-next-line: param-type-mismatch
        CommandSpec.new(1, CommandSpec.CommandKind.Build, matcher)
    end, "name: expected string, got number")
end

T["CommandSpec"]["fails to validate kind"] = function()
    has_error(function()
        ---@diagnostic disable-next-line: param-type-mismatch
        CommandSpec.new("test", 1, matcher)
    end, "kind: expected string, got number")
end

T["CommandSpec"]["fails to validate matcher"] = function()
    -- has_error(function()
    --     CommandSpec.new("test", CommandSpec.CommandKind.Build, matcher, {
    --         ---@diagnostic disable-next-line: assign-type-mismatch
    --         parser = "parser",
    --     })
    -- end, "options.parser: expected a Parser class instance, got string")
end

T["CommandSpec"]["fails to validate parser"] = function()
    has_error(function()
        CommandSpec.new("test", CommandSpec.CommandKind.Build, matcher, {
            ---@diagnostic disable-next-line: assign-type-mismatch
            parser = "parser",
        })
    end, "options.parser: expected a Parser class instance, got string")
end

return T
