local float = {}

local function create_preview_win(buffer, bufpos, zindex, options)
    local enter = options.enter or options.enter or false
    local cur_win = vim.api.nvim_get_current_win()

    return vim.api.nvim_open_win(buffer, enter, {
        relative = "win",
        width = options.width,
        height = options.height,
        border = options.border,
        bufpos = bufpos,
        zindex = zindex,
        win = vim.api.nvim_get_current_win(),
        title = options.title,
        title_pos = options.title_pos or "left",
    })
end

function float.open_preview(target, position, options)
    local buffer = type(target) == "string" and vim.uri_to_bufnr(target) or target
    local bufpos = { vim.fn.line "." - 1, vim.fn.col "." } -- FOR relative='win'
    local dismiss = options.dismiss_on_move

    options = options or {}

    local preview_window = create_preview_win(buffer, bufpos, options.zindex, options)

    if options.opacity then
        vim.api.nvim_set_option_value("winblend", options.opacity, { win = preview_window })
    end

    vim.api.nvim_win_set_var(preview_window, "terminal-diagnostics.nvim", 1)

    if dismiss then
        -- TODO: Convert to lua
        vim.api.nvim_command(("autocmd CursorMoved <buffer> ++once lua require('goto-preview').dismiss_preview(%d)"):format(preview_window))
    end

    -- Set position of the preview buffer equal to the target position so that
    -- correct preview position shows
    vim.api.nvim_win_set_cursor(preview_window, position)

    if type(options.post_open_hook) == "function" then
        local success, result = pcall(options.post_open_hook, buffer, preview_window)
    end

    return preview_window
end

return float
