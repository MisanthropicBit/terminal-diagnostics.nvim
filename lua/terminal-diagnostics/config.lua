---@type terminal-diagnostics.Config
---@diagnostic disable-next-line: missing-fields
local config = {}

local notify = require("terminal-diagnostics.notify")

local config_loaded = false

---@class terminal-diagnostics.ConfigTerminalDiagnostics
---@field create_options terminal-diagnostics.DiagnosticsCreateOptions

---@class terminal-diagnostics.ConfigTerminalOptions
---@field enabled     boolean?
---@field diagnostics terminal-diagnostics.ConfigTerminalDiagnostics

---@class terminal-diagnostics.Config
---@field include                 string[]? Command specs to include, excluding all others
---@field highlight_context_lines boolean?  Highlight context lines when creating terminal diagnostics
---@field parallel                boolean?  Whether to proceess diagnostics in parallel or not
---@field terminal                terminal-diagnostics.ConfigTerminalOptions
---@field search                  fun(parse_result: terminal-diagnostics.parser.ParseResult)

---@type terminal-diagnostics.Config
local default_config = {
    include = nil,
    highlight_context_lines = true,
    parallel = false,
    diagnostics = {
        terminal_diagnostics = {
            filter = function() end,
        },
        project_diagnostics = {
            filter = function() end,
        },
    },
    terminal = {
        enabled = true,
        diagnostics = {
            create_options = {
                terminal_diagnostics = true,
            },
        },
    },
    search = function(parse_result)
        local name = parse_result.command_spec:name()
        local message = parse_result.values.message
        local code = parse_result.values.code

        if not message then
            notify.error("No error message found")
            return
        end

        local query = ('"%s" %s'):format(name, message)

        if code then
            query = query .. " " .. code
        end

        local utils = require("terminal-diagnostics.utils")
        local encoded_query = utils.url.encode(query)
        local _, open_error = vim.ui.open("https://duckduckgo.com/?q=" .. encoded_query)

        if open_error then
            notify.error("Failed to search", open_error)
        end
    end,
}

--- Check if a value is a valid string option
---@param value any
---@return boolean
function config.valid_string_option(value)
    return value ~= nil and type(value) == "string" and #value > 0
end

---@param object table<string, unknown>
---@param schema table<string, unknown>
---@return table
local function validate_schema(object, schema)
    local errors = {}

    for key, value in pairs(schema) do
        if type(value) == "string" then
            local ok, err = pcall(vim.validate, { [key] = { object[key], value } })

            if not ok then
                table.insert(errors, err)
            end
        elseif type(value) == "table" then
            if type(object) ~= "table" then
                table.insert(errors, "Expected a table at key " .. key)
            else
                if vim.is_callable(value[1]) then
                    local ok, err = pcall(vim.validate, {
                        [key] = { object[key], value[1], value[2] },
                    })

                    if not ok then
                        table.insert(errors, err)
                    end
                else
                    vim.list_extend(errors, validate_schema(object[key], value))
                end
            end
        end
    end

    return errors
end

--- Validate a config
---@param _config terminal-diagnostics.Config
---@return boolean
---@return any?
function config.validate(_config)
    -- TODO: Validate superfluous keys

    -- stylua: ignore start
    local config_schema = {
        include = string_list_validator,
        highlight_context_lines = "boolean",
        parallel = "boolean",
    }
    -- stylua: ignore end

    local errors = validate_schema(_config, config_schema)

    return #errors == 0, errors
end

---@type terminal-diagnostics.Config
local _user_config = default_config

---Use in testing
---@private
function config._default_config()
    return default_config
end

---@param user_config? terminal-diagnostics.Config
function config.setup(user_config)
    _user_config = vim.tbl_deep_extend("keep", user_config or {}, default_config)

    local ok, error = config.validate(_user_config)

    if not ok then
        notify.error("Errors found in config: " .. table.concat(error, "\n"))
    else
        config_loaded = true
    end

    return ok
end

setmetatable(config, {
    __index = function(_, key)
        -- Lazily load configuration so there is no need to call configure explicitly
        if not config_loaded then
            config.setup()
        end

        return _user_config[key]
    end,
})

return config
