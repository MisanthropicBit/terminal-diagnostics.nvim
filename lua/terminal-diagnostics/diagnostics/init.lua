local diagnostics = {}

local ns_id = vim.api.nvim_create_namespace("terminal-diagnostics.diagnostics")
local processor

---@class terminal-diagnostics.QuickfixOptions
---@field open  boolean?
---@field focus boolean?
---@field title string?

---@class terminal-diagnostics.DiagnosticsBufferOptions : terminal-diagnostics.SequentialOutputProcessorOptions

local diagnosticToString = {
    [vim.diagnostic.severity.ERROR] = "error",
    [vim.diagnostic.severity.WARN] = "warning",
    [vim.diagnostic.severity.INFO] = "info",
    [vim.diagnostic.severity.HINT] = "hint",
}

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
---@param options terminal-diagnostics.DiagnosticsBufferOptions
function diagnostics.create_for_buffer(buffer, options)
    if not processor then
        local SequentialOutputProcessor =
            require("terminal-diagnostics.output_processors.sequential")

        processor = SequentialOutputProcessor.new()
    end

    processor.process({
        buffer = buffer,
        input = {},
        output = vim.api.nvim_buf_get_lines(buffer, 0, -1, true),
        has_ansi = false,
    }, options)
end

-- { {
--     code = "2322",
--     col = 26,
--     context = { "", "6     return null;", "      ~~~~~~~~~~~~", "", "" },
--     end_ = {
--       col = 76,
--       lnum = 4
--     },
--     lnum = 6,
--     message = "Type 'null' is not assignable to type 'Person'.",
--     path = "main.ts",
--     severity = 1,
--     start = {
--       col = 0,
--       lnum = 4
--     }
--   } }

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.from_parse_results(parse_results)
    local _diagnostics = {}

    for _, parse_result in ipairs(parse_results) do
        local buffer = 0

        -- TODO: How to handle multiple valid paths?
        if parse_result.paths[1] then
            buffer = vim.uri_to_bufnr(vim.uri_from_fname(parse_result.paths[1]))
        end

        local diagnostic = diagnostics.create({
            bufnr = buffer,
            lnum = parse_result.lnum - 1,
            col = parse_result.col - 1,
            severity = parse_result.severity,
            message = parse_result.message,
            source = parse_result.source,
            code = parse_result.code,
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
        local severity = parse_result.values.severity or "info"
        local code = parse_result.values.code

        if code and code == "" then
            code = nil
        end

        local diagnostic = diagnostics.create({
            bufnr = parse_result.buffer,
            lnum = parse_result.range.start.lnum,
            end_lnum = parse_result.range.end_.lnum,
            col = parse_result.range.start.col,
            end_col = parse_result.range.end_.col,
            severity = severity,
            message = ("%s %s"):format(
                parse_result.kind,
                severity
            ),
            source = parse_result.source,
            code = code,
        })

        table.insert(terminal_diagnostics, diagnostic)
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
