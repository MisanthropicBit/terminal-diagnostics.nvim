local health = {}

local config = require("terminal-diagnostics.config")

local min_neovim_version = "0.11.0"

function health.check()
    vim.health.start("terminal-diagnostics.nvim")

    if vim.fn.has("nvim-" .. min_neovim_version) == 1 then
        vim.health.ok(("has neovim %s+"):format(min_neovim_version))
    else
        vim.health.error("terminal-diagnostics.nvim requires at least neovim " .. min_neovim_version)
    end

    local ok, error = config.validate(config)

    if ok then
        vim.health.ok("found no errors in config")
    else
        vim.health.error("config has errors: " .. error)
    end
end

return health
