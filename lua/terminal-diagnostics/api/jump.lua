local jump = {}

local builtins = require("terminal-diagnostics.builtins")
local notify = require("terminal-diagnostics.notify")
local utils = require("terminal-diagnostics.utils")

-- local ns = vim.api.nvim_create_namespace("terminal-diagnostics.extmarks")
-- local augroup = vim.api.nvim_create_augroup("terminal-diagnostics.augroup", {
--     clear = true,
-- })

---@class terminal-diagnostics.JumpOptions
---@field wrap  boolean?
---@field count integer?

---@class terminal-diagnostics.ClosestCommandSpec
---@field distance     integer
---@field match        terminal-diagnostics.Match?
---@field command_spec terminal-diagnostics.CommandSpec?

---@class (exact) terminal-diagnostics.ApiResult
---@field command_spec terminal-diagnostics.CommandSpec
---@field results      terminal-diagnostics.MatchResult2[]

---@class terminal-diagnostics.LastJumpLocation
---@field match terminal-diagnostics.Match
---@field result terminal-diagnostics.MatchResult

--- Save the last location where we jumped to for quickly opening a location
---@type terminal-diagnostics.ApiResult?
local last_jump_result

---@param command_specs terminal-diagnostics.CommandSpec[]
---@param match_options { buffer: integer, lnum: integer, col: integer, count: integer }
---@return terminal-diagnostics.ClosestCommandSpec
local function get_closest_command_spec(command_specs, match_options)
    ---@type terminal-diagnostics.ClosestCommandSpec
    local closest_command_spec = {
        distance = math.huge,
        match = nil,
        command_spec = nil,
    }

    for _, command_spec in ipairs(command_specs) do
        local matcher = command_spec:matcher()
        vim.print(command_spec:name())
        local match = matcher:find_match_start(match_options)

        if match then
            local distance = math.abs(match.from.lnum - match_options.lnum)

            if distance ~= 0 and distance < closest_command_spec.distance then
                closest_command_spec.distance = distance
                closest_command_spec.match = match
                closest_command_spec.command_spec = command_spec
            end
        end
    end

    return closest_command_spec
end

---@param options terminal-diagnostics.JumpOptions?
---@return terminal-diagnostics.ApiResult?
function jump.jump(options)
    local _options = options or { count = 1, wrap = false }
    local count = _options.count or 1

    if count == 0 then
        count = 1
    end

    local buffer = vim.api.nvim_get_current_buf()
    local lnum, col = unpack(utils.cursor.get())
    local command_specs = builtins.get()
    local match_options = {
        buffer = buffer,
        lnum = lnum,
        col = col,
        count = count,
        extract = false,
    }
    ---@type terminal-diagnostics.ClosestCommandSpec
    local closest
    local idx = 1

    while idx <= math.abs(count) do
        closest = get_closest_command_spec(command_specs, match_options)

        if not closest.command_spec then
            if not _options.wrap then
                break
            end

            if count < 0 then
                match_options.lnum = vim.fn.line("$")
                match_options.col = 0
            else
                match_options.lnum = 1
                match_options.col = 0
            end
        else
            if idx < math.abs(count) then
                match_options.lnum = closest.match.to.lnum
                match_options.col = closest.match.to.col
            else
                match_options.lnum = closest.match.from.lnum
                match_options.col = closest.match.from.col - 1
            end

            idx = idx + 1
        end

        vim.api.nvim_win_set_cursor(0, { match_options.lnum, match_options.col })
    end

    if not closest.command_spec then
        -- Reset cursor to original position
        vim.api.nvim_win_set_cursor(0, { lnum, col })

        notify.error(
            ("No matches found %s cursor"):format(count > 0 and "below" or "above")
        )

        return
    end

    -- Get the full match
    local results = closest.command_spec:matcher():match(match_options)

    if #results > 0 then
        last_jump_result = {
            command_spec = closest.command_spec,
            results = results,
        }
    end

    -- vim.api.nvim_exec_autocmds("User", {
    --     pattern = "TerminalDiagnosticsPostJump",
    --     modeline = false,
    --     data = {
    --         command_spec = closest.command_spec,
    --         buffer = buffer,
    --         ns = ns,
    --         augroup = augroup,
    --     },
    -- })

    -- if config.jump.posthook then
    --     config.jump.posthook({
    --         match = match,
    --         data = data,
    --         buffer = buffer,
    --         ns = ns,
    --         augroup = augroup,
    --     })
    -- end

    return {
        command_spec = closest.command_spec,
        results = results,
    }
end

---@return terminal-diagnostics.ApiResult?
function jump.get_last_jump_result()
    return last_jump_result
end

return jump
