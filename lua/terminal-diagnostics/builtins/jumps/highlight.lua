---@class terminal-diagnostics.UnderlineJumpOptions
---@field hl_group (string | string[])?

---@param options terminal-diagnostics.UnderlineJumpOptions
return function(options)
    ---@param context terminal-diagnostics.PostJumpContext
    return function(context)
        local match = context.match
        local hl_group = options.hl_group or { "Underlined", "ErrorMsg" }

        local ok, extmark_id = pcall(
            vim.api.nvim_buf_set_extmark,
            context.buffer,
            context.ns,
            match.range.from.lnum,
            match.range.from.col,
            {
                hl_group = hl_group,
                end_row = match.range.to.lnum,
                end_col = match.range.to.col,
            }
        )

        if not ok then
            require("terminal-diagnostics.notify").error(
                "Failed to create extmark for postjump hook 'underline': "
                .. tostring(extmark_id)
            )
        end

        vim.schedule(function()
            vim.api.nvim_create_autocmd("CursorMoved", {
                group = context.augroup,
                buffer = context.buffer,
                once = true,
                callback = function()
                    vim.api.nvim_buf_del_extmark(context.buffer, context.ns, extmark_id)
                end,
            })
        end)
    end
end
