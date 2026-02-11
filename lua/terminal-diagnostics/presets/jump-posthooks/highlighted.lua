return function(options)
    return function(context)
        local match = context.match

        ---@type integer[]
        local extmark_ids = {}
        local spec_keys = require("terminal-diagnostics.matchers")

        for _, key in ipairs(spec_keys) do
            local pos = context.submatches[key]

            if pos then
                local hl_group = require("terminal-diagnostics.highlights").hl_group_for_spec_key(key)

                table.insert(
                    extmark_ids,
                    vim.api.nvim_buf_set_extmark(
                        context.buffer,
                        context.ns,
                        match.from.lnum - 1,
                        pos.start_col - 1,
                        {
                            hl_group = hl_group,
                            end_row = match.to.lnum - 1,
                            end_col = pos.end_col,
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
