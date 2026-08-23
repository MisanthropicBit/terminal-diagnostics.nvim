local option_parser = {}

---@alias terminal-diagnostics.OptionSpec "number" | "string" | "boolean" | "flag" | string[]

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
            return nil,
                ("Failed to convert '%s' to number for option '%s'"):format(value, key)
        end

        return number
    elseif spec == "boolean" then
        if value == "true" then
            return true
        elseif value == "false" then
            return false
        else
            return nil,
                ("Failed to convert '%s' to boolean for option '%s'"):format(value, key)
        end
    end
end

---@param command_args string[]
---@param options terminal-diagnostics.Options
---@return terminal-diagnostics.OptionParseResult
function option_parser.parse(command_args, options)
    ---@type terminal-diagnostics.OptionParseResult
    local args = { result = {}, errors = {} }
    local positional_args = {}

    -- Handle positional arguments
    for idx, option in pairs(options) do
        if type(idx) ~= "number" then
            goto continue1
        end

        local arg = command_args[idx]

        if not arg then
            ---@diagnostic disable-next-line: undefined-field
            if not option.optional then
                table.insert(
                    args.errors,
                    ("Missing required positional argument at position %d"):format(idx)
                )
            end

            goto continue1
        end

        table.insert(positional_args, idx)

        if type(option) == "table" then
            ---@cast option string[]
            if vim.tbl_contains(option, arg) then
                args.result[idx] = arg
            else
                table.insert(
                    args.errors,
                    ("Invalid positional argument '%s' at position %d"):format(arg, idx)
                )
            end
        else
            table.insert(
                args.errors,
                ("Positional arguments must be a list of choices at position %d"):format(
                    idx
                )
            )
        end

        ::continue1::
    end

    -- Handle key-value arguments
    for idx, arg in ipairs(command_args) do
        if vim.tbl_contains(positional_args, idx) then
            goto continue2
        end

        local pair = vim.split(arg, "=", { plain = true, trimempty = true })

        if #pair == 1 then
            args.result[arg] = true
        elseif #pair == 2 then
            local key, value = unpack(pair)
            local spec = options[key]

            if not spec then
                table.insert(
                    args.errors,
                    ("Invalid option '%s' at position %d"):format(arg, idx)
                )
                goto continue2
            end

            if vim.islist(spec) then
                ---@cast spec string[]
                if vim.tbl_contains(spec, value) then
                    args.result[key] = value
                else
                    table.insert(
                        args.errors,
                        ("Invalid choice '%s' for option '%s' at position %d"):format(
                            value,
                            key,
                            idx
                        )
                    )
                end

                goto continue2
            end

            local result, err = convert_value(key, value, spec)

            if not err then
                args.result[key] = result
            else
                table.insert(args.errors, err)
            end
        else
            table.insert(args.errors, ("Malformed argument '%s'"):format(arg))
        end

        ::continue2::
    end

    return args
end

return option_parser
