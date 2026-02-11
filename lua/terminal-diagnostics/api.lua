local api = {}

local matchers = require("terminal-diagnostics.matchers")
local notify = require("terminal-diagnostics.notify")
local ui = require("terminal-diagnostics.ui")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.JumpOptions
---@field wrap  boolean?
---@field count integer?

---@class terminal-diagnostics.ClosestMatch
---@field distance integer
---@field match    terminal-diagnostics.Match?
---@field matcher  terminal-diagnostics.Matcher?

---@class terminal-diagnostics.SelectOptions
---@field lookahead boolean? Scan forward and try to find a match
---@field outer     boolean? Select the "outer" (instead of inner) error message

---@class terminal-diagnostics.ApiResult
---@field match terminal-diagnostics.Match
---@field data  terminal-diagnostics.MatchResult

--- Save the last location where we jumped to for quickly opening a location
---@type { [1]: terminal-diagnostics.Match, [2]: terminal-diagnostics.MatchResult }?
local last_jump_location

---@enum terminal-diagnostics.OpenType
local OpenType = {
    Split = "split",
    Vertical = "vertical",
    Tab = "tab",
    Edit = "edit",
    Preview = "preview",
    Float = "float",
}

---@param selected_matchers terminal-diagnostics.Matcher[]
---@param match_options { buffer: integer, lnum: integer, col: integer, count: integer }
---@return terminal-diagnostics.ClosestMatch
local function get_closest_match(selected_matchers, match_options)
    ---@type terminal-diagnostics.ClosestMatch
    local closest_match = {
        distance = math.huge,
        match = nil,
        matcher = nil,
    }

    for _, matcher in ipairs(selected_matchers) do
        local match = matcher.match_start(match_options)

        if match then
            local distance = math.abs(match.from.lnum - match_options.lnum)

            -- log.debug(matcher.name(), distance)

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
function api.jump(options)
    local _options = options or { count = 1, wrap = false }
    local count = _options.count or 1

    if count == 0 then
        count = 1
    end

    local buffer = vim.api.nvim_get_current_buf()
    local lnum, col = unpack(utils.get_cursor())
    local all_matchers = matchers.get_all()
    local match_options = {
        buffer = buffer,
        lnum = lnum,
        col = col,
        count = count,
    }
    ---@type terminal-diagnostics.ClosestMatch
    local closest_match
    local idx = 1

    while idx <= math.abs(count) do
        closest_match = get_closest_match(all_matchers, match_options)

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

    last_jump_location = {
        closest_match.matcher.match({
            buffer = buffer,
            lnum = lnum,
            col = col,
            count = count,
        }),
    }
end

---@param type terminal-diagnostics.OpenType
---@param result terminal-diagnostics.ApiResult
local function open_match(type, result)
    local abspath = vim.fs.abspath(result.data.path)

    if vim.fn.filereadable(abspath) == 0 then
        notify.error("File '%s' is not readable", abspath)
        return
    end

    if type == OpenType.Split then
        vim.cmd.split(abspath)
    elseif type == OpenType.Vertical then
        vim.cmd("vertical split " .. abspath)
    elseif type == OpenType.Tab then
        vim.cmd.tabnew(abspath)
    elseif type == OpenType.Edit then
        vim.cmd.edit(abspath)
    elseif type == OpenType.Preview then
        -- TODO: Set cursor in preview window
        vim.cmd.pedit(abspath)
    elseif type == OpenType.Float then
        ui.float.open_preview({
            target = abspath,
            width = 0.5,
            height = 0.45,
            enter = true,
            title = abspath,
            title_pos = "left",
            border = "rounded",
            close_on_move = true,
            post_open_hook = function()
                vim.api.nvim_win_set_cursor(
                    0,
                    { result.data.lnum, result.data.col - 1 }
                )
            end,
        })
    else
        assert(false, ("Invalid open type '%s'"):format(type))
    end

    if type ~= OpenType.Preview then
        vim.api.nvim_win_set_cursor(0, { result.data.lnum, result.data.col - 1 })
    end
end

---@param location { [1]: terminal-diagnostics.Match, [2]: terminal-diagnostics.MatchResult }?
---@return boolean
local function last_jump_location_is_valid(location)
    if not location or not location[1] then
        return false
    end

    local _, lnum, col, _ = unpack(vim.fn.getpos("."))

    if lnum >= location[1].from.lnum and lnum <= location[1].to.lnum then
        if col >= location[1].from.col and col <= location[1].to.col then
            return true
        end
    end

    return false
end

---@param buffer integer
---@parm options table
---@return terminal-diagnostics.ApiResult?
function api.find_at_cursor(buffer, options)
    local match, data
    local valid = last_jump_location_is_valid(last_jump_location)

    if valid then
        ---@cast last_jump_location -nil
        match = last_jump_location[1]
    else
        last_jump_location = nil
        local all_matchers = matchers.get_all()

        for _, matcher in ipairs(all_matchers) do
            match, data = matcher.match_at_cursor({ buffer = buffer })

            if match then
                break
            end
        end
    end

    if not match then
        return
    end

    return { match = match, data = data }
end

---@param options table
function api.open(options)
    local buffer = vim.api.nvim_get_current_buf()
    local result = api.find_at_cursor(buffer)

    if not result then
        notify.error("Found no matches under cursor")
        return
    elseif not result.data.path then
        notify.error("Match does not contain a path to open")
        return
    end

    open_match(options.type, result)
end

---@param options terminal-diagnostics.SelectOptions?
function api.select(options)
    local result = api.find_at_cursor(0, {})

    if not result then
        if options and options.lookahead then
            result = api.jump({ count = 1, wrap = false })

            if not result then
                return
            end
        else
            return
        end
    end

    local match = result.match

    vim.api.nvim_win_set_cursor(0, { match.to.lnum, match.to.col - 1 })
    vim.cmd([[normal! v]])
    vim.api.nvim_win_set_cursor(0, { match.from.lnum, match.from.col - 1 })
end

return api
