local builtins = {}

-- TODO: Make this automatic
local builtin_command_specs = {
    "clang",
    "eslint-compact",
    "eslint-stylish",
    "jest",
    "rustc",
    "tsc",
}

---@param filter string[]?
---@return terminal-diagnostics.CommandSpec[]
function builtins.get(filter)
    local names = builtin_command_specs

    if filter then
        names = vim.tbl_filter(function(name)
            return vim.tbl_contains(filter, name)
        end, names)
    end

    -- Many of the patterns were borrowed and modified from
    -- stevearc/overseer.nvim and ej-shafran/compile-mode.nvim
    local command_specs = vim.tbl_map(function(name)
        return require("terminal-diagnostics.command_specs." .. name)
    end, names)

    -- Append the fallback command spec to the end so it tried last when e.g.
    -- jumping between errors
    table.insert(command_specs, #command_specs, require("terminal-diagnostics.command_specs.fallback"))

    return command_specs
end

return builtins
