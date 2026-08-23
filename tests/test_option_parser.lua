local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local option_parser = require("terminal-diagnostics.option_parser")

local option_spec = {
    bool = "boolean",
    number = "number",
    flag = "flag",
    string = "string",
    choice = { "yes", "no" },
    [3] = { "inner", "outer", optional = true },
}

local T = new_set()

T["option_parser"] = new_set()

T["option_parser"]["parses valid command line options"] = function()
    local command_args = {
        "bool=true",
        "number=1.2",
        "inner",
        "flag",
        "string=hello",
        "choice=yes",
    }

    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = {
            bool = true,
            number = 1.2,
            flag = true,
            string = "hello",
            choice = "yes",
            [3] = "inner",
        },
        errors = {},
    })
end

T["option_parser"]["handles invalid option flag"] = function()
    local command_args = { "bool=true", "nope=hey" }
    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = { bool = true },
        errors = { "Invalid option 'nope=hey' at position 2" },
    })
end

T["option_parser"]["handles invalid conversions"] = function()
    local command_args = { "bool=ok", "number=hello" }
    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = {},
        errors = {
            "Failed to convert 'ok' to boolean for option 'bool'",
            "Failed to convert 'hello' to number for option 'number'",
        },
    })
end

T["option_parser"]["handles invalid choices"] = function()
    local command_args = { "bool=false", "choice=maybe"  }
    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = { bool = false },
        errors = { "Invalid choice 'maybe' for option 'choice' at position 2" },
    })
end

T["option_parser"]["handles invalid position argument"] = function()
    local command_args = { "bool=false", "choice=no", "circumference"  }
    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = {
            bool = false,
            choice = "no",
        },
        errors = { "Invalid positional argument 'circumference' at position 3" },
    })
end

T["option_parser"]["handles positional arguments without valid choice"] = function()
    local command_args = { "ok" }
    local result = option_parser.parse(command_args, { "ok" })

    eq(result, {
        result = {},
        errors = { "Positional arguments must be a list of choices at position 1" },
    })
end

T["option_parser"]["handles required positional arguments"] = function()
    local command_args = {}
    local result = option_parser.parse(command_args, { { "ok", optional = false } })

    eq(result, {
        result = {},
        errors = { "Missing required positional argument at position 1" },
    })
end

T["option_parser"]["handles malformed arguments"] = function()
    local command_args = { "bool=ok=yes"  }
    local result = option_parser.parse(command_args, option_spec)

    eq(result, {
        result = {},
        errors = { "Malformed argument 'bool=ok=yes'" },
    })
end

return T
