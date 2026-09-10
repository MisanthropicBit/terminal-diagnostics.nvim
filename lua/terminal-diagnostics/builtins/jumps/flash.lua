---@class terminal-diagnostics.FlashJumpOptions
---@field hl_group (string | string[])?
---@field fg       boolean?
---@field duration number?

---@param options terminal-diagnostics.FlashJumpOptions
---@return terminal-diagnostics.PostJumpFunc
return function(options)
    return function(context)
        local timer = vim.uv.new_timer()

        if not timer then
            require("terminal-diagnostics.log").error("Failed to create timer for flash.lua")
            return
        end

        local match = context.match
        local hl_group = options.hl_group or { "Search", "ErrorMsg" }

        local extmark_id = vim.api.nvim_buf_set_extmark(
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

        local duration = options.duration or 300

        timer:start(duration, 0, function()
            vim.api.nvim_buf_del_extmark(context.buffer, context.ns, extmark_id)
            timer:stop()
            timer:close()
        end)
    end
end
