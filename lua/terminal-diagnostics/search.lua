local notify = require("terminal-diagnostics.notify")

-- TODO: Make this such that multiple strings give a ui choice and
-- vim.ui.open is a configurable default? Then users can either
-- search the internet or pass the error to an AI etc.
local search = {}

---@class terminal-diagnostics.SearchActionItem
---@field name   string
---@field action fun()

---@alias terminal-diagnostics.SearchFunc fun(parse_result: terminal-diagnostics.parser.ParseResult): terminal-diagnostics.SearchActionItem[]

local base_url = "https://duckduckgo.com/?q="

---@param code string
---@return string
local function create_haskell_error_page_url(code)
    return ("https://errors.haskell.org/messages/%s/"):format(code)
end

---@param code string
---@return string
local function create_eslint_error_page_url(code)
    return ("https://eslint.org/docs/latest/rules/%s"):format(code)
end

---@return string
function search.base_url()
    return base_url
end

---@param parse_result terminal-diagnostics.parser.ParseResult
---@return string?
function search.create_query_parameter(parse_result)
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

    return require("terminal-diagnostics.utils").url.encode(query)
end

---@param parse_result terminal-diagnostics.parser.ParseResult
---@return terminal-diagnostics.SearchActionItem[]
function search.search(parse_result)
    local name = parse_result.command_spec:name()
    local url

    -- TODO: Probably move this into command specs
    if parse_result.values.code then
        if name == "haskell" then
            url = create_haskell_error_page_url(parse_result.values.code)
        elseif vim.startswith(name, "eslint") then
            url = create_eslint_error_page_url(parse_result.values.code)
        end
    end

    if not url then
        url = base_url .. search.create_query_parameter(parse_result)
    end

    if not url then
        return {}
    end

    return {
        {
            name = "Search the internet",
            action = function()
                local _, open_error = vim.ui.open(url)

                if open_error then
                    notify.error("Failed to open url", open_error)
                end
            end,
        },
    }
end

return search
