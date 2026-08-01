local diagnostics = {}

local SequentialOutputProcessor = require("terminal-diagnostics.output_processors.sequential")
local ParallelOutputProcessor = require("terminal-diagnostics.output_processors.parallel")
local notify = require("terminal-diagnostics.notify")

local ns_id = vim.api.nvim_create_namespace("terminal-diagnostics.diagnostics")
local processor

-- TODO:
---@alias terminal-diagnostics.DiagnosticsFilter fun(): boolean

---@class terminal-diagnostics.QuickfixOptions
---@field open  boolean?
---@field focus boolean?
---@field title string?

---@class terminal-diagnostics.DiagnosticsCreateOptions
---@field terminal_diagnostics boolean?
---@field diagnostics          boolean?
---@field quickfix             (boolean | terminal-diagnostics.QuickfixOptions)?
---@field locationlist         (boolean | terminal-diagnostics.QuickfixOptions)?
---@field trouble              boolean?
---@field parallel             boolean?
---@field notify               boolean?
---@field filter               terminal-diagnostics.DiagnosticsFilter?
---@field stable               boolean? If the buffer is stable and won't be modified

---@return integer
function diagnostics.namespace_id()
    return ns_id
end

---@param diagnostic vim.Diagnostic
---@return vim.Diagnostic
function diagnostics.create(diagnostic)
    return vim.tbl_extend(
        "force",
        {
            source = "terminal-diagnostics.nvim",
        },
        diagnostic,
        {
            namespace = ns_id,
            user_data = { generated_by = "terminal-diagnostics.nvim" },
        }
    )
end

---@param buffer integer
---@param options terminal-diagnostics.DiagnosticsCreateOptions
function diagnostics.create_for_buffer(buffer, options)
    if not processor then
        if options.parallel then
            processor = ParallelOutputProcessor.new()
        else
            processor = SequentialOutputProcessor.new()
        end
    end

    ---@type terminal-diagnostics.TerminalOutputEvent
    local event = {
        buffer = buffer,
        input = {},
        output = vim.api.nvim_buf_get_lines(buffer, 0, -1, true),
        has_ansi = false,
    }

    local result = processor:process(event)

    if not result then
        return
    end

    -- Create terminal diagnostics from parse results
    if options.terminal_diagnostics then
        local terminal_diagnostics = diagnostics.terminal_from_parse_results(result.parse_results)

        diagnostics.set(buffer, terminal_diagnostics, {})
    end

    local project_diagnostics = {}
    local populate_list = options.quickfix == true or options.locationlist == true

    -- Create project diagnostics from parse results
    if options.diagnostics or populate_list then
        project_diagnostics = diagnostics.from_parse_results(result.parse_results)

        -- TODO: Need to resolve paths to absolute paths and load the buffers
        -- for those files.
        --
        -- Alternatively, set diagnostics for the buffers that are already open
        -- and cache the rest. When a new buffer is opened, check if the
        -- filename matches, set diagnostics, and clear cache entry (what if the
        -- buffer is unloaded and then loaded again?). This is probably better
        -- since we might otherwise load an enormous amount of buffers

        if #project_diagnostics > 0 then
            diagnostics.set(0, project_diagnostics, {})
        end
    end

    -- Populate the quickfix/location list with the diagnostics
    if populate_list and #project_diagnostics > 0 then
        local sources = vim.tbl_map(function(spec)
            return spec:name()
        end, result.command_specs)

        if options.quickfix then
            diagnostics.setqflist(project_diagnostics, {
                open = true,
                focus = false,
                title = ("terminal-diagnostics.nvim (%s)"):format(vim.iter(sources):join(", ")),
            })
        end

        if options.locationlist then
            local win_id = vim.api.nvim_get_current_win()

            vim.fn.setloclist(win_id, {}, " ", {})
        end
    end

    -- Notify the user
    if options.notify then
        notify.info("Processed terminal output")
    end

    -- Fire autocommand to signal completion of processor
    vim.api.nvim_exec_autocmds("User", {
        pattern = "terminal-diagnostics.processor.completed",
        modeline = false,
        data = { event = event },
    })
end

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.from_parse_results(parse_results)
    local _diagnostics = {}

    for _, parse_result in ipairs(parse_results) do
        local buffer = 0

        -- TODO: How to handle multiple valid paths?
        if parse_result.values.paths[1] then
            buffer = vim.uri_to_bufnr(vim.uri_from_fname(parse_result.values.paths[1]))
        end

        local diagnostic = diagnostics.create({
            bufnr = buffer,
            lnum = parse_result.values.lnum - 1,
            col = parse_result.values.col - 1,
            end_lnum = 0, -- TODO:
            end_col = 0, -- TODO:
            severity = vim.diagnostic.severity[parse_result.values.severity],
            message = parse_result.values.message,
            source = parse_result.source,
            code = parse_result.values.code,
            valid = buffer ~= nil,
        })

        table.insert(_diagnostics, diagnostic)
    end

    return _diagnostics
end

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.terminal_from_parse_results(parse_results)
    local terminal_diagnostics = {}

    for _, parse_result in ipairs(parse_results) do
        if not parse_result.values then
            goto continue
        end

        local severity = parse_result.values.severity or "info"
        local code = parse_result.values.code

        if code and code == "" then
            code = nil
        end

        local diagnostic = diagnostics.create({
            bufnr = parse_result.buffer,
            lnum = parse_result.range.from.lnum + 1,
            end_lnum = parse_result.context.range.to.lnum + 1,
            col = parse_result.range.from.col,
            end_col = parse_result.range.to.col,
            severity = vim.diagnostic.severity[severity],
            message = ("%s %s"):format(parse_result.kind, severity:lower()),
            source = parse_result.source,
            code = code,
        })

        table.insert(terminal_diagnostics, diagnostic)

        :: continue ::
    end

    return terminal_diagnostics
end

---@param buffer integer
---@param _diagnostics vim.Diagnostic[]
---@param options vim.diagnostic.Opts?
function diagnostics.set(buffer, _diagnostics, options)
    vim.diagnostic.set(ns_id, buffer, _diagnostics, options)
end

---@param _diagnostics vim.Diagnostic[]
---@param options terminal-diagnostics.QuickfixOptions?
function diagnostics.setqflist(_diagnostics, options)
    local _options = options or {}

    -- TODO: What to do about multiple paths here?
    local qf_items = vim.diagnostic.toqflist(_diagnostics)

    -- for idx = 1, #qf_items do
    --     local qf_item = qf_items[idx]
    --     local diagnostic = _diagnostics[idx]
    --
    --     -- Abuse the module name of the quickfix item to signal the
    --     -- source of the diagnostic
    --     qf_item.module = diagnostic.source
    -- end

    -- vim.print(vim.inspect(qf_items))

    -- TODO: Use context to replace existing quickfix?
    vim.fn.setqflist({}, " ", {
        items = qf_items,
        title = _options.title or "terminal-diagnostics.nvim",
        context = { is_terminal_diagnostics = true },
    })

    if _options.open then
        vim.cmd.copen()

        if _options.focus == false then
            vim.cmd.wincmd("p")
        end
    end
end

---@param options vim.diagnostic.Opts?
function diagnostics.setup(options)
    vim.api.nvim_create_autocmd("BufReadPost", {
        callback = function(event)
            -- TODO: Allow users to set when diagnostics are set (e.g. if there is no lsp)

            -- 1. Get absolute filename
            local filename = vim.api.nvim_buf_get_name(event.buf)

            -- 2. See if there is a cache entry for the filename
            -- local result = diagnostics_cache:get(filename)

            -- 3. Set diagnostics and remove cache entry
            -- diagnostics.set(event.buf, result, {})
            -- diagnostics_cache:remove(filename)
        end,
    })

    local diagnostic_config = vim.tbl_deep_extend("force", {
        underline = false,
        severity_sort = true,
        virtual_text = {
            spacing = 1,
            current_line = false,
            source = false,
            prefix = "●",
        },
        virtual_lines = false,
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = " ",
                [vim.diagnostic.severity.WARN] = " ",
                [vim.diagnostic.severity.INFO] = " ",
                [vim.diagnostic.severity.HINT] = "󰌵 ",
            },
            numhl = {
                [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
                [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
                [vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
                [vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
            },
            linehl = false,
        },
        -- TODO: vim.diagnostic.open_float returns the float buffer and window
        -- id so perhaps use that to load the target buffer
        float = {
            header = { "terminal-diagnostics.nvim", "Title" },
            source = false,
            -- prefix = function()
            --     vim.print("buffer efoijsef " .. tostring(vim.api.nvim_get_current_buf()))
            --     return ""
            -- end,
            -- format = function()
            --     vim.print(vim.api.nvim_get_current_buf())
            --     return ""
            -- end
        },
    }, options or {})

    vim.diagnostic.config(diagnostic_config, diagnostics.namespace_id())
end

return diagnostics
