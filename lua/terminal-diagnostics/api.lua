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
---@field from     terminal-diagnostics.EditorPosition
---@field to       terminal-diagnostics.EditorPosition
---@field matcher  terminal-diagnostics.Matcher?

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
        from = {
            lnum = 0,
            col = 0,
        },
        to = {
            lnum = 0,
            col = 0,
        },
        matcher = nil,
    }

    for _, matcher in ipairs(selected_matchers) do
        local match = matcher.match_start(match_options)

        if match then
            local distance = match.from.lnum - match_options.lnum

            -- Only consider matches that are positive or negative depending on direction
            if match_options.count > 0 then
                if distance <= 0 then
                    goto continue
                end
            elseif match_options.count < 0 then
                if distance >= 0 then
                    goto continue
                end
            end

            if math.abs(distance) < closest_match.distance then
                closest_match.distance = math.abs(distance)
                closest_match.from = match.from
                closest_match.to = match.to
                closest_match.matcher = matcher
            end
        end

        ::continue::
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
                match_options.lnum = closest_match.to.lnum
                match_options.col = closest_match.to.col
            else
                match_options.lnum = closest_match.from.lnum
                match_options.col = closest_match.from.col - 1
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

---@param buffer integer
---@param type terminal-diagnostics.OpenType
---@param match any
local function open_match(buffer, type, match)
    local abspath = vim.fs.abspath(match.path)

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
        vim.cmd.pedit(abspath)
    elseif type == OpenType.Float then
        ui.float.open_preview({
            path = abspath,
            enter = true,
            title = vim.api.nvim_buf_get_name(buffer),
            title_pos = "left",
            posthook = function()
                vim.api.nvim_win_set_buf(0, buffer)
                vim.api.nvim_win_set_cursor(0, { match.lnum, match.col - 1 })
            end,
        })
    else
        assert(false, ("Invalid open type '%s'"):format(type))
    end

    vim.api.nvim_win_set_cursor(0, { match.lnum - 1, match.col })
end

---@param location { [1]: terminal-diagnostics.Match, [2]: terminal-diagnostics.MatchResult }?
---@return boolean
local function last_jump_location_is_valid(location)
    if not location then
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
    local match = api.find_at_cursor(buffer)

    if not match then
        notify.error("Found no matches under cursor")
        return
    end

    open_match(buffer, options.type, match)
end

return api
