local extmark = {}

---@param namespace integer
---@param buffer integer
---@param range terminal-diagnostics.Range
---@param url string
function extmark.create_link(namespace, buffer, range, url)
    vim.api.nvim_buf_set_extmark(buffer, namespace, range.from.lnum, range.from.col, {
        end_line = range.to.lnum,
        end_col = range.to.col,
        url = url,
    })
end

return extmark
