local guess_command = {}

---@param command string[]?
---@return terminal-diagnostics.CommandSpec?
function guess_command.guess(command)
    if not command then
        return
    end

    if command[1] == "tsc" then
        return require("terminal-diagnostics.command_specs.tsc")
    elseif command[1] == "npx" then
        return guess_command(vim.list_slice(command, 2))
    end
end

return guess_command
