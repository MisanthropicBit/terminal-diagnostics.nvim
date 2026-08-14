local diagnostics = {}

local SequentialOutputProcessor =
    require("terminal-diagnostics.output_processors.sequential")
local ParallelOutputProcessor = require("terminal-diagnostics.output_processors.parallel")
-- local buffer_cache = require("terminal-diagnostics.buffer_cache.buffer_cache")

local ns_id = vim.api.nvim_create_namespace("terminal-diagnostics.diagnostics")
local processor

-- TODO:
---@alias terminal-diagnostics.DiagnosticsFilter fun(): boolean

---@class terminal-diagnostics.ListOptions
---@field open  boolean?
---@field focus boolean?
---@field title string?

---@class terminal-diagnostics.DiagnosticsCreateOptions
---@field terminal_diagnostics boolean?
---@field diagnostics          boolean?
---@field quickfix             (boolean | terminal-diagnostics.ListOptions)?
---@field locationlist         (boolean | terminal-diagnostics.ListOptions)?
---@field trouble              (boolean | terminal-diagnostics.ListOptions)?
---@field parallel             boolean?
---@field filter               terminal-diagnostics.DiagnosticsFilter?
---@field stable               boolean? If the buffer is stable and won't be modified

--- Determine if a buffer is stable and probably won't be modified in
--- the future so we can cache the parse results
---@param buffer integer
---@return boolean
local function is_stable_buffer(buffer)
    local bufname = vim.fn.bufname(buffer)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = buffer })

    if buftype == "terminal" then
        if vim.startswith(bufname, "term://") then
            return false
        end

        return true
    end

    return false
end

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
            user_data = vim.tbl_extend(
                "force",
                { generated_by = "terminal-diagnostics.nvim" },
                diagnostic.user_data or {}
            ),
        }
    )
end

---@param project_diagnostics vim.Diagnostic[]
local function set_project_diagnostics(project_diagnostics)
    -- TODO: Handle command specs like jest where we need to create project
    -- diagnostics that group parse results together (header + multiple error
    -- lines). We either can:
    --
    -- 1. Label each parse result with its group and later re-group them
    -- 2. Group header + error lines for command specs that set a flag
    if #project_diagnostics > 0 then
        local buffers = vim.api.nvim_list_bufs()

        ---@type table<integer, vim.Diagnostic[]>
        local diagnostics_per_buffer = vim.defaulttable(function()
            return {}
        end)

        -- Find buffers whose paths correspond to a project diagnostic
        for _, diagnostic in ipairs(project_diagnostics) do
            for _, buf in ipairs(buffers) do
                if vim.api.nvim_buf_get_name(buf) == diagnostic.user_data.path then
                    table.insert(diagnostics_per_buffer[buf], diagnostic)
                end
            end
        end

        -- Set diagnostics for all buffers. Buffers for paths in project
        -- diagnostics will previously have been added as 'unlisted' to
        -- the buffer list via vim.uri_to_bufnr
        for buffer, buffer_diagnostics in pairs(diagnostics_per_buffer) do
            diagnostics.set(buffer, buffer_diagnostics, {})
        end
    end

    return project_diagnostics
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
        local terminal_diagnostics =
            diagnostics.from_terminal_parse_results(result.parse_results)

        diagnostics.set(buffer, terminal_diagnostics, {})

        -- if options.stable or is_stable_buffer(buffer) then
        --     buffer_cache.set(buffer, result.parse_results)
        -- end
    end

    local project_diagnostics = {}
    local populate_list = options.quickfix == true or options.locationlist == true

    -- Create project diagnostics from parse results
    if options.diagnostics or populate_list then
        project_diagnostics = diagnostics.from_parse_results(result.parse_results)

        if options.diagnostics then
            set_project_diagnostics(project_diagnostics)
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
                title = ("terminal-diagnostics.nvim (%s)"):format(
                    vim.iter(sources):join(", ")
                ),
            })
        end

        if options.locationlist then
            local win_id = vim.api.nvim_get_current_win()

            vim.fn.setloclist(win_id, {}, " ", {})
        end

        if options.trouble then
            local has_trouble, _ = pcall(require, "trouble")

            if has_trouble then
                vim.cmd("Trouble qflist open")
            end
        end
    end
end

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.from_parse_results(parse_results)
    local _diagnostics = {}

    for _, parse_result in ipairs(parse_results) do
        local buffer = 0
        local path = parse_result.values.paths[1]
        local severity = parse_result.values.severity or "info"

        -- TODO: How to handle multiple valid paths?
        if path then
            buffer = vim.uri_to_bufnr(vim.uri_from_fname(path))
        end

        local message = parse_result.values.message or "No message"

        if parse_result.context and #parse_result.context.lines > 0 then
            message = message .. "\n" .. table.concat(parse_result.context.lines, "\n")
        end

        local diagnostic = diagnostics.create({
            bufnr = buffer,
            lnum = parse_result.values.lnum - 1,
            col = parse_result.values.col - 1,
            end_lnum = parse_result.values.lnum,
            end_col = 0, -- TODO:
            severity = vim.diagnostic.severity[severity],
            message = message,
            source = parse_result.command_spec:name(),
            code = parse_result.values.code,
            valid = buffer ~= nil,
            user_data = { path = path },
        })

        table.insert(_diagnostics, diagnostic)
    end

    return _diagnostics
end

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.from_terminal_parse_results(parse_results)
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
            message = ("%s %s"):format(
                parse_result.command_spec:kind(),
                severity:lower()
            ),
            source = parse_result.command_spec:name(),
            code = code,
        })

        table.insert(terminal_diagnostics, diagnostic)

        ::continue::
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
---@param options terminal-diagnostics.ListOptions?
function diagnostics.setqflist(_diagnostics, options)
    local _options = options or {}

    local qf_items = vim.diagnostic.toqflist(_diagnostics)

    for idx = 1, #qf_items do
        local qf_item = qf_items[idx]
        local diagnostic = _diagnostics[idx]

        -- Abuse the module name of the quickfix item to signal the source of
        -- the diagnostic
        if diagnostic.source then
            local relative_path = vim.fn.fnamemodify(diagnostic.user_data.path, ":.")

            qf_item.module = ("%s (%s)"):format(relative_path, diagnostic.source)
        end
    end

    -- TODO: Use context to replace existing quickfix?
    vim.fn.setqflist({}, " ", {
        items = qf_items,
        title = _options.title or "terminal-diagnostics.nvim",
        context = { is_terminal_diagnostics = true },
    })

    if _options.open then
        local win_id = vim.api.nvim_get_current_win()
        diagnostics.copen(win_id)

        if _options.focus == false then
            vim.api.nvim_set_current_win(win_id) -- TODO: Necessary?
        end
    end
end

---@param win_id integer
function diagnostics.copen(win_id)
    vim.api.nvim_win_call(win_id, vim.cmd.copen)
end

---@param options vim.diagnostic.Opts?
function diagnostics.setup(options)
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
