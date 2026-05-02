local open_command_complete_args

local function open_command_complete()
    if not open_command_complete_args then
        -- TODO: Move OpenType to separate file?
        open_command_complete_args =
            vim.tbl_values(require("terminal-diagnostics.api.open").OpenType)
    end

    return open_command_complete_args
end

vim.api.nvim_create_user_command("TermDiagVersion", function()
    vim.print(require("terminal-diagnostics").version())
end, { nargs = 0, desc = "Print the current version" })

vim.api.nvim_create_user_command("TermDiagQuickfix", function() end, {
    nargs = 0,
    range = true,
    desc = "Open the last command output, or a selected range, in the quickfix buffer",
})

vim.api.nvim_create_user_command(
    "TermDiagPrevious",
    function() end,
    { nargs = 0, count = 1, desc = "Jump to the [count] previous error" }
)

vim.api.nvim_create_user_command(
    "TermDiagNext",
    function() end,
    { nargs = 0, count = 1, desc = "Jump to the [count] next error" }
)

vim.api.nvim_create_user_command("TermDiagOpen", function() end, {
    nargs = "?",
    complete = open_command_complete,
    desc = "Open the error under the cursor",
})

vim.api.nvim_create_user_command("TermDiagSelect", function() end, {
    nargs = "?",
    complete = function()
        return { "inner", "outer" }
    end,
    desc = "Visually select the error under cursor",
})
