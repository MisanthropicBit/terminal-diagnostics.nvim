local log = require("terminal-diagnostics.log")
local diagnostics_cache = require("terminal-diagnostics.diagnostics.diagnostics_cache")
local diagnostics = require("terminal-diagnostics.diagnostics")

local buffer_tracker = {}

local augroup

function buffer_tracker.init()
    if not augroup then
        log.debug("Already initialised buffer tracker")
        return
    end

    augroup = vim.api.nvim_create_augroup("terminal-diagnostics.buffer_tracker", {
        clear = true,
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        augroup = augroup,
        callback = function(event)
            local bufname = vim.api.nvim_buf_get_name(event.buf)
            local _diagnostics = diagnostics_cache.get(bufname)

            if not _diagnostics or _diagnostics.active then
                return
            end

            log.debug("Found inactive cached diagnostics for buffer", event.buf)

            _diagnostics.active = true
            diagnostics.set(event.buf, diagnostics)
        end,
    })

    vim.api.nvim_create_autocmd("BufLeave", {
        augroup = augroup,
        callback = function(event)
            diagnostics_cache:remove(event.buf)
        end,
    })
end

return buffer_tracker
