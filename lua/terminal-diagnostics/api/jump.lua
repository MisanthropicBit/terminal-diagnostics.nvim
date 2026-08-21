local jump = {}

local builtins = require("terminal-diagnostics.command_specs")
local notify = require("terminal-diagnostics.notify")
local utils = require("terminal-diagnostics.utils")
-- local buffer_cache = require("terminal-diagnostics.buffer_cache.buffer_cache")

local ns = vim.api.nvim_create_namespace("terminal-diagnostics.extmarks")
local augroup = vim.api.nvim_create_augroup("terminal-diagnostics.augroup", {
    clear = true,
})

---@class terminal-diagnostics.JumpOptions
---@field wrap        boolean?
---@field count       integer?
---@field keep_cursor boolean?

---@class terminal-diagnostics.ClosestCommandSpec
---@field distance     integer
---@field match        terminal-diagnostics.Match?
---@field command_spec terminal-diagnostics.CommandSpec?

---@class (exact) terminal-diagnostics.ApiResult
---@field command_spec terminal-diagnostics.CommandSpec
---@field matches      terminal-diagnostics.Match[]

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
        local match = matcher:find_match_start(match_options)

        if match then
            local distance = math.abs(match.range.from.lnum - match_options.lnum)

            if distance ~= 0 and distance < closest_command_spec.distance then
                closest_command_spec.distance = distance
                closest_command_spec.match = match
                closest_command_spec.command_spec = command_spec
            end
        end
    end

    return closest_command_spec
end

---@param buffer integer
---@param lnum   integer
---@param count  integer
---@return terminal-diagnostics.ApiResult?
local function get_cached_result(buffer, lnum, count)
    ---@type terminal-diagnostics.BufferCacheEntry?
    local cached = buffer_cache.get(buffer)

    if cached and cached.parse_results then
        ---@type terminal-diagnostics.parser.ParseResult
        local result = cached.parse_results:find_closest(lnum, count)

        return {
            command_spec = result.command_spec,
            matches = result.matches,
        }
    end
end

local function find_closest_match() end

--- Find a consecutive match if the last jump result was consecutive
--- (possibly has a match on the next line)
---comment
---@param match         terminal-diagnostics.Match
---@param command_spec  terminal-diagnostics.CommandSpec
---@param match_options table
---@return terminal-diagnostics.ClosestCommandSpec?
local function find_consecutive_match(match, command_spec, match_options)
    if not match.spec.consecutive then
        return
    end

    local matcher = command_spec:matcher()
    local next_match = matcher:find_match_start(match_options)

    -- We matched the next line with the same command spec
    if next_match and next_match.range.from.lnum == match.range.from.lnum + 1 then
        return {
            distance = 1,
            match = match,
            command_spec = command_spec,
        }
    end
end

-- TODO: Perhaps cache positions and their resulting jump results in a sorted list
-- for unstable buffers?

---@param options terminal-diagnostics.JumpOptions?
---@return terminal-diagnostics.ApiResult?
function jump.jump(options)
    local buffer = vim.api.nvim_get_current_buf()
    local lnum, col = unpack(utils.cursor.get())
    local _options = options or { count = 1, wrap = false, keep_cursor = false }
    local count = _options.count or 1

    if count == 0 then
        count = 1
    end

    -- local cached_result = get_cached_result(buffer, lnum, count)
    --
    -- if cached_result then
    --     return cached_result
    -- end

    local command_specs = builtins.get()

    -- TODO: Change lnum and col to a position
    local match_options = {
        buffer = buffer,
        lnum = lnum - 1,
        col = col,
        count = count,
        extract = false,
    }
    ---@type terminal-diagnostics.ClosestCommandSpec?
    local closest
    local idx = 1

    if last_jump_result then
        closest = find_consecutive_match(
            last_jump_result.matches[1],
            last_jump_result.command_spec,
            match_options
        )
    end

    while idx <= math.abs(count) do
        if closest then
            closest = find_consecutive_match(closest.match, closest.command_spec, match_options)
        end

        if not closest then
            closest = get_closest_command_spec(command_specs, match_options)
        end

        if not closest.command_spec then
            if not _options.wrap then
                break
            end

            if count < 0 then
                match_options.lnum = vim.fn.line("$") - 1
                match_options.col = 0
            else
                match_options.lnum = 0
                match_options.col = 0
            end
        else
            if idx < math.abs(count) then
                match_options.lnum = closest.match.range.to.lnum
                match_options.col = closest.match.range.to.col
            else
                match_options.lnum = closest.match.range.from.lnum
                match_options.col = closest.match.range.from.col
            end

            idx = idx + 1
        end

        vim.api.nvim_win_set_cursor(0, { match_options.lnum + 1, match_options.col })
    end

    ---@cast closest -nil

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
            matches = results,
        }
    end

    vim.api.nvim_exec_autocmds("User", {
        pattern = "TerminalDiagnosticsPostJump",
        modeline = false,
        data = {
            -- command_spec = closest.command_spec,
            buffer = buffer,
            ns = ns,
            augroup = augroup,
            -- groups = function()
            --     return require("terminal-diagnostics.patterns").parse_subgroups(
            --         closest.match.text,
            --         ---@diagnostic disable-next-line: param-type-mismatch
            --         closest.match.spec
            --     )
            -- end,
        },
    })

    if _options.keep_cursor then
        vim.api.nvim_win_set_cursor(0, { lnum, col })
    end

    return {
        command_spec = closest.command_spec,
        matches = results,
    }
end

---@return terminal-diagnostics.ApiResult?
function jump.get_last_jump_result()
    return last_jump_result
end

return jump
