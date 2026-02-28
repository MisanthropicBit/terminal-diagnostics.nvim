local builtins = {}

local builtin_command_specs = { "tsc" }

---@param filter string[]?
---@return terminal-diagnostics.CommandSpec[]
function builtins.get(filter)
    local names = builtin_command_specs

    if filter then
        names = vim.tbl_filter(function(name)
            return vim.tbl_contains(filter, name)
        end, names)
    end

    -- Many of the patterns were borrowed and modified from stevearc/overseer.nvim and ej-shafran/compile-mode.nvim
    return vim.tbl_map(function(name)
        return require("terminal-diagnostics.builtins." .. name)
    end, names)
end

return builtins
