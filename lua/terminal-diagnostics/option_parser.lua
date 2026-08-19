local option_parser = {}

-- TODO: Add arg count check
-- TODO: Parse positional args

---@alias terminal-diagnostics.OptionSpec "number" | "string" | "boolean" | "flag"

---@alias terminal-diagnostics.Options table<string, terminal-diagnostics.OptionSpec>

---@class terminal-diagnostics.OptionParseResult
---@field result table<string, number | string | boolean>
---@field errors string[]

---@param key string
---@param value string
---@param spec terminal-diagnostics.OptionSpec
---@return any?, string?
local function convert_value(key, value, spec)
    if not spec or spec == "string" then
        return value
    end

    if spec == "number" then
        local number = tonumber(value)

        if not number then
            return nil, ("Failed to convert '%s' to a number for option '%s'"):format(value, key)
        end
    elseif spec == "boolean" then
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        else
            return nil, ("Failed to convert '%s' to a boolean for option '%s'"):format(value, key)
        end
    end
end

---@param command_args string[]
---@param options terminal-diagnostics.Options
---@return terminal-diagnostics.OptionParseResult
function option_parser.parse(command_args, options)
    ---@type terminal-diagnostics.OptionParseResult
    local args = {
        result = {},
        errors = {},
    }

    for _, arg in ipairs(command_args) do
        local pair = vim.split(arg, "=", { plain = true, trimempty = true })

        if #pair == 1 then
            args.result[arg] = true
        elseif #pair == 2 then
            local key, value = unpack(pair)
            local result, err = convert_value(key, value, options[key])

            if result then
                args.result[key] = result
            else
                table.insert(args.errors, err)
            end
        else
            table.insert(args.errors, ("Malformed argument '%s'"):format(arg))
        end
    end

    return args
end

return option_parser
