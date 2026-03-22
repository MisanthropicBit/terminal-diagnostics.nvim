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

---@class terminal-diagnostics.ClosestMatch
---@field distance integer
---@field match    terminal-diagnostics.Match?
---@field matcher  terminal-diagnostics.Matcher?

---@class terminal-diagnostics.ApiResult
---@field spec  terminal-diagnostics.MatchSpec
---@field match terminal-diagnostics.Match

---@class terminal-diagnostics.LastJumpLocation
---@field match terminal-diagnostics.Match
---@field result terminal-diagnostics.MatchResult

--- Save the last location where we jumped to for quickly opening a location
---@type terminal-diagnostics.ApiResult?
local last_jump_match

---@param command_specs terminal-diagnostics.CommandSpec[]
---@param match_options { buffer: integer, lnum: integer, col: integer, count: integer }
---@return terminal-diagnostics.ClosestMatch
local function get_closest_match(command_specs, match_options)
    ---@type terminal-diagnostics.ClosestMatch
    local closest_match = {
        distance = math.huge,
        match = nil,
        matcher = nil,
    }

    for _, command_spec in ipairs(command_specs) do
        local matcher = command_spec:matcher()
        local match = matcher.match_start(match_options)

        if match then
            local distance = math.abs(match.from.lnum - match_options.lnum)

            if distance ~= 0 and distance < closest_match.distance then
                closest_match.distance = distance
                closest_match.match = match
                closest_match.matcher = matcher
            end
        end
    end

    return closest_match
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
    local lnum, col = unpack(utils.get_cursor())
    local command_specs = builtins.get()
    local match_options = {
        buffer = buffer,
        lnum = lnum,
        col = col,
        count = count,
        extract = false,
    }
    ---@type terminal-diagnostics.ClosestMatch
    local closest_match
    local idx = 1

    while idx <= math.abs(count) do
        closest_match = get_closest_match(command_specs, match_options)

        if not closest_match.matcher then
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
                match_options.lnum = closest_match.match.to.lnum
                match_options.col = closest_match.match.to.col
            else
                match_options.lnum = closest_match.match.from.lnum
                match_options.col = closest_match.match.from.col - 1
            end

            idx = idx + 1
        end

        vim.api.nvim_win_set_cursor(0, { match_options.lnum, match_options.col })
    end

    if not closest_match.matcher then
        -- Reset cursor to original position
        vim.api.nvim_win_set_cursor(0, { lnum, col })
        notify.error("No matches found")
        return
    end

    local spec, match = closest_match.matcher.match(match_options)

    if spec and match then
        last_jump_match = { spec = spec, match = match }
    end

    -- if config.jump.posthook then
    --     config.jump.posthook({
    --         match = match,
    --         data = data,
    --         buffer = buffer,
    --         ns = ns,
    --         augroup = augroup,
    --     })
    -- end

    return { spec = spec, match = match }
end

---@return terminal-diagnostics.ApiResult?
function jump.get_last_jump_match()
    return last_jump_match
end

return jump
