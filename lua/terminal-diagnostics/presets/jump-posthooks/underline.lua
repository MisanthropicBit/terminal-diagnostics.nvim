---@class terminal-diagnostics.UnderlinePosthook
---@field hl_group (string | string[])?

---@param options terminal-diagnostics.UnderlinePosthook
return function(options)
    return function(context)
        local match = context.match
        local hl_group = options.hl_group or { "Underlined", "ErrorMsg" }

        local extmark_id = vim.api.nvim_buf_set_extmark(
            context.buffer,
            context.ns,
            match.from.lnum - 1,
            match.from.col - 1,
            {
                hl_group = hl_group,
                end_row = match.to.lnum - 1,
                end_col = match.to.col,
            }
        )

        vim.schedule(function()
            vim.api.nvim_create_autocmd("CursorMoved", {
                group = context.augroup,
                buffer = context.buffer,
                once = true,
                callback = function()
                    vim.api.nvim_buf_del_extmark(
                        context.buffer,
                        context.ns,
                        extmark_id
                    )
                end,
            })
        end)
    end
end
