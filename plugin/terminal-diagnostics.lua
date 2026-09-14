local open_command_complete_args

local term_diag_create_options = {
    terminal_diagnostics = "flag",
    diagnostics = "flag",
    locationlist = "flag",
    quickfix = "flag",
    trouble = "flag",
    parallel = "flag",
    stable = "flag",
    links = "flag",
    command_spec = "string",
}

local function open_command_complete()
    if not open_command_complete_args then
        open_command_complete_args =
            vim.tbl_values(require("terminal-diagnostics.api.open_type"))
    end

    return open_command_complete_args
end

---@param options terminal-diagnostics.Options
---@return fun(): string[]
local function create_complete_function_from_options(options)
    return function()
        return vim.tbl_keys(options)
    end
end

vim.api.nvim_create_user_command("TermDiagVersion", function()
    vim.print(require("terminal-diagnostics").version())
end, { nargs = 0, desc = "Print the current version" })

vim.api.nvim_create_user_command("TermDiagCreate", function(args)
    local cmd_args = require("terminal-diagnostics.option_parser").parse(
        args.fargs,
        term_diag_create_options
    )

    local diagnostics = require("terminal-diagnostics.diagnostics")

    diagnostics.create_for_buffer(vim.api.nvim_get_current_buf(), cmd_args.result)
end, {
    nargs = "+",
    range = true,
    desc = "Create diagnostics or quickfix/locationlist items for the current buffer or a selected range",
    complete = create_complete_function_from_options(term_diag_create_options),
})

vim.api.nvim_create_user_command("TermDiagCreateLastCommand", function(args)
    local diagnostics = require("terminal-diagnostics.diagnostics")
    local handler = require("terminal-diagnostics.terminal.terminal_request_handler")
    local last_event = handler.last_command_event(0)

    if not last_event then
        require("terminal-diagnostics.notify").error(
            "No last command event registered for buffer"
        )
        return
    end

    diagnostics.create_for_event(last_event, cmd_args)
end, {
    nargs = 0,
    count = 1,
    bang = true,
    desc = "Create diagnostics or quickfix/locationlist items for the last command output",
})

vim.api.nvim_create_user_command("TermDiagFirst", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local result =
        require("terminal-diagnostics.api").jump.jump({ wrap = false, count = 1 })

    if not result then
        vim.api.nvim_win_set_cursor(0, cursor)
    end
end, { nargs = 0, desc = "Jump to the first error" })

vim.api.nvim_create_user_command("TermDiagLast", function()
    local cursor = vim.api.nvim_win_get_cursor(0)

    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })

    local result =
        require("terminal-diagnostics.api").jump.jump({ wrap = false, count = -1 })

    if not result then
        vim.api.nvim_win_set_cursor(0, cursor)
    end
end, { nargs = 0, desc = "Jump to the last error" })

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
    local OpenType = require("terminal-diagnostics.api.open_type")
    local open_type = args.fargs[1] or OpenType.Split

    open.open({ type = open_type })
end, {
    nargs = "?",
    complete = open_command_complete,
    desc = "Open the error under the cursor",
})

vim.api.nvim_create_user_command("TermDiagSelect", function(args)
    local fargs = args.fargs
    local select = require("terminal-diagnostics.api").select
    local cmd_args = require("terminal-diagnostics.option_parser").parse(args.fargs, {
        [1] = { "inner", "outer" },
        [2] = vim.tbl_values(select.SelectField)
    })

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
        lookahead = args.bang,
        outer = select_type == "outer" and true or false,
        field = select_field
    })
end, {
    nargs = "+",
    bang = true,
    complete = function()
        return { "inner", "outer" }
    end,
    desc = "Visually select the error under cursor",
})

vim.api.nvim_create_user_command("TermDiagLog", function(args)
    local log_path = require("terminal-diagnostics.log").default_logger():path()

    vim.cmd(("%s split %s"):format(args.mods, log_path))
end, {
    nargs = 0,
    desc = "Open the log file for the default logger",
})

vim.api.nvim_create_user_command("TermDiagSearch", function()
    local api_utils = require("terminal-diagnostics.api.api_utils")
    local _, parse_result = api_utils.find_parse_result_at_cursor(0)
    local notify = require("terminal-diagnostics.notify")

    if not parse_result then
        notify.error("No match under cursor")
        return
    end

    local config = require("terminal-diagnostics.config")
    local search_items = config.terminal.search(parse_result)

    if #search_items == 0 then
        notify.warn("No search options available. Please set config.terminal.search")
        return
    elseif #search_items == 1 then
        search_items[1].action()
    else
        vim.ui.select(search_items, {
            format_item = function(item)
                return item.name
            end,
            prompt = "Select search action",
        }, function(_, idx)
            if not idx then
                return
            end

            search_items[idx].action()
        end)
    end
end, {
    nargs = 0,
    desc = "Search one or more sources for the error under the cursor",
})
