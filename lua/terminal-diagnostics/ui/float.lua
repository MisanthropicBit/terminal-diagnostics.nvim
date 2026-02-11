local float = {}

local notify = require("terminal-diagnostics.notify")

---@class terminal-diagnostics.FloatOptions
---@field target string | integer?
---@field width integer?
---@field height integer?
---@field enter boolean?
---@field title string?
---@field title_pos string?
---@field post_open_hook fun()?
---@field close_on_move boolean?
---@field zindex integer?
---@field border ('none'|'single'|'double'|'rounded'|'solid'|'shadow'|string[])?

local default_win_open_options = {
    width = 0.5,
    height = 0.45,
    enter = true,
    title_pos = "left",
    border = "rounded",
    close_on_move = true,
}

local function clamp(value)
    return math.floor(value + 0.5)
end

---@param value integer
---@param max_value integer
---@return integer
local function resolve_dimension(value, max_value)
    if not value then
        value = 0.5
    end

    if value <= 1.0 then
        return clamp(value * max_value)
    end

    return clamp(value)
end

---@param width integer
---@param height integer
---@return integer, integer
local function resolve_dimensions(width, height)
    return resolve_dimension(width, vim.o.columns),
        resolve_dimension(height, vim.o.lines)
end

---@param options terminal-diagnostics.FloatOptions?
function float.open_preview(options)
    local _options = vim.tbl_extend("force", default_win_open_options, options or {})

    -- TODO: Validate other options
    vim.validate("post_open_hook", _options.post_open_hook, "function")

    local buffer = vim.api.nvim_create_buf(true, false)
    local bufpos = { vim.fn.line(".") - 1, vim.fn.col(".") }

    _options.width, _options.height = resolve_dimensions(_options.width, _options.height)

    local window = vim.api.nvim_open_win(buffer, _options.enter, {
        relative = "win",
        width = _options.width,
        height = _options.height,
        border = _options.border,
        bufpos = bufpos,
        zindex = _options.zindex,
        win = vim.api.nvim_get_current_win(),
        title = _options.title,
        title_pos = _options.title_pos,
    })

    vim.api.nvim_win_set_var(window, "terminal-diagnostics.nvim", 1)

    if _options.close_on_move and not _options.enter then
        vim.api.nvim_create_autocmd("CursorMoved", {
            buffer = buffer,
            once = true,
            callback = function()
                -- TODO:
            end,
        })
    end

    if type(_options.target) == "number" then
        vim.cmd.buffer(_options.target)
    else
        vim.cmd.edit(_options.target)
    end

    if _options.post_open_hook then
        local success, err = pcall(_options.post_open_hook, buffer, window)

        if not success then
            notify.error("Failed calling post_open_hook: " .. tostring(err))
        end
    end

    return window
end

return float
