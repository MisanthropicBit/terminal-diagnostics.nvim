---@class terminal-diagnostics.VirtualLinesJumpOptions

---@param options terminal-diagnostics.VirtualLinesJumpOptions
return function(options)
    ---@param context terminal-diagnostics.PostJumpContext
    return function(context)
        local match = context.match

        ---@type integer[]
        local extmark_ids = {}
        local spec_keys = require("terminal-diagnostics.matchers").match_spec_keys()
        local subgroups = context.subgroups()
        local hl_groups = options.hl_groups or {}

        for _, key in ipairs(spec_keys) do
            local pos = subgroups[key]

            if pos then
                local hl_group = hl_groups[key] or require("terminal-diagnostics.highlights").hl_group_for_spec_key(key)

                table.insert(
                    extmark_ids,
                    vim.api.nvim_buf_set_extmark(
                        context.buffer,
                        context.ns,
                        match.range.from.lnum,
                        pos.start_col,
                        {
                            hl_group = hl_group,
                            end_row = match.range.to.lnum,
                            end_col = pos.end_col,
                            virt_text = { { key, hl_group } },
                            virt_text_win_col = pos.start_col,
                            virt_lines_above = false,
                        }
                    )
                )
            end
        end

        vim.schedule(function()
            vim.api.nvim_create_autocmd("CursorMoved", {
                group = context.augroup,
                buffer = context.buffer,
                once = true,
                callback = function()
                    for _, extmark_id in ipairs(extmark_ids) do
                        vim.api.nvim_buf_del_extmark(
                            context.buffer,
                            context.ns,
                            extmark_id
                        )
                    end
                end,
            })
        end)
    end
end
