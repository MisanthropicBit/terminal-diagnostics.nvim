local select = {}

---@class terminal-diagnostics.SelectOptions
---@field lookahead boolean? Scan forward and try to find a match
---@field outer     boolean? Select the "outer" (instead of inner) error message

---@param options terminal-diagnostics.SelectOptions?
function select.select(options)
    local result = require("terminal-diagnostics.api.cursor").find_at_cursor(0, {})

    if not result then
        if options and options.lookahead then
            result = require("terminal-diagnostics.api.jump").jump({ count = 1, wrap = false })

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

return select
