local open_command_complete_args

local function open_command_complete()
    if not open_command_complete_args then
        open_command_complete_args =
            vim.tbl_values(require("terminal-diagnostics.api.open_type").OpenType)
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

vim.api.nvim_create_user_command("TermDiagLocationList", function() end, {
    nargs = 0,
    range = true,
    desc = "Open the last command output, or a selected range, in the location list",
})

vim.api.nvim_create_user_command("TermDiagCreate", function() end, {
    nargs = 0,
    range = true,
    desc =
    "Create terminal diagnostics, project-wide diagnostics, quickfix items, location list items, or trouble.nvim items for the last command output or a selected range",
})

vim.api.nvim_create_user_command("TermDiagPrevious", function(args)
    require("terminal-diagnostics.api").jump.jump({
        wrap = args.bang,
        count = -args.count,
    })
end, { nargs = 0, count = 1, bang = true, desc = "Jump to the [count] previous error" })

vim.api.nvim_create_user_command("TermDiagNext", function(args)
    require("terminal-diagnostics.api").jump.jump({
        wrap = args.bang,
        count = args.count,
    })
end, { nargs = 0, count = 1, bang = true, desc = "Jump to the [count] next error" })

vim.api.nvim_create_user_command("TermDiagOpen", function(args)
    local open = require("terminal-diagnostics.api").open
    local open_type = args.fargs[1] or open.OpenType.Split

    open.open({ type = open_type })
end, {
    nargs = "?",
    complete = open_command_complete,
    desc = "Open the error under the cursor",
})

vim.api.nvim_create_user_command("TermDiagSelect", function(args)
    local fargs = args.fargs

    if #fargs > 2 then
        vim.notify("Too many arguments, expected 0-2 arguments", vim.log.levels.ERROR)
        return
    end

    local select_type = fargs[1]

    if select_type ~= nil and not vim.tbl_contains({ "inner", "outer" }, select_type) then
        vim.notify(
            ("Unknown first argument '%s', expected 'inner' or 'outer'"):format(
                select_type
            ),
            vim.log.levels.ERROR
        )

        return
    end

    local select_field = fargs[2]
    local select = require("terminal-diagnostics.api").select

    if select_field ~= nil then
        local select_field_values = vim.tbl_values(select.SelectField)

        if not vim.tbl_contains(select_field_values, select_field) then
            vim.notify(
                ("Unknown first argument '%s', expected 'inner' or 'outer'"):format(
                    select_type
                ),
                vim.log.levels.ERROR
            )

            return
        end
    end

    require("terminal-diagnostics.api").select.select({
        lookahead = false,
        outer = select_type == "outer" and true or false,
        field = select_field
    })
end, {
    nargs = "+",
    complete = function()
        return { "inner", "outer" }
    end,
    desc = "Visually select the error under cursor",
})
