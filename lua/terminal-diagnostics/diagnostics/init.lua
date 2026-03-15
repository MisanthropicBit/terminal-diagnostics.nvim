local diagnostics = {}

local ns_id = vim.api.nvim_create_namespace("terminal-diagnostics.diagnostics")

---@return integer
function diagnostics.namespace_id()
    return ns_id
end

---@param source string
---@param diagnostic vim.Diagnostic
---@return vim.Diagnostic
function diagnostics.create(source, diagnostic)
    return vim.tbl_extend("force", diagnostic, {
        source = source or "terminal-diagnostics.nvim",
        namespace = ns_id,
        user_data = { generated_by = "terminal-diagnostics.nvim" },
    })
end

---@param buffer integer
function diagnostics.create_for_buffer(buffer)
    -- Parse buffer contents and return diagnostics
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
    local SequentialOutputProcessor =
        require("terminal-diagnostics.output_processors.sequential")
    local processor = SequentialOutputProcessor.new()

    processor.process({
        buffer = buffer,
        input = {},
        output = lines,
        has_ansi = false,
    }, {
        terminal_diagnostics = true,
    })
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
        local diagnostic = diagnostics.create("terminal-diagnostics.nvim", {
            bufnr = 0, -- TODO: Should be part of parse result
            lnum = parse_result.lnum,
            col = parse_result.col,
            severity = parse_result.severity,
            message = parse_result.message,
            source = parse_result.source,
            code = parse_result.code,
        })

        table.insert(_diagnostics, diagnostic)
    end

    return _diagnostics
end

---@param parse_results terminal-diagnostics.parser.ParseResult[]
---@return vim.Diagnostic[]
function diagnostics.terminal_from_parse_results(parse_results)
    local terminal_diagnostics = {}

    local temp = {
        [vim.diagnostic.severity.ERROR] = "error",
        [vim.diagnostic.severity.WARN] = "warning",
        [vim.diagnostic.severity.INFO] = "info",
        [vim.diagnostic.severity.HINT] = "hint",
    }

    for _, parse_result in ipairs(parse_results) do
        local diagnostic = diagnostics.create("terminal-diagnostics.nvim", {
            -- bufnr = 0, -- TODO: Should be part of parse result
            lnum = parse_result.start.lnum - 1,
            end_lnum = parse_result.end_.lnum - 1,
            col = parse_result.start.col,
            end_col = parse_result.end_.col,
            severity = parse_result.severity,
            message = ("%s %s %s"):format(parse_result.source, parse_result.kind, temp[parse_result.severity]),
            source = parse_result.source,
            code = parse_result.code,
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

function diagnostics.setqflist(_diagnostics, options)
    local qf_items = vim.diagnostic.toqflist(_diagnostics)

    -- TODO: Use context to replace existing quickfix?
    vim.fn.setqflist({}, "a", {
        items = qf_items,
        title = options.title or "terminal-diagnostics.nvim",
        context = { is_terminal_diagnostics = true },
    })

    if options.open then
        vim.cmd.copen()
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
        }
    }, options or {})

    vim.diagnostic.config(diagnostic_config, diagnostics.namespace_id())
end

return diagnostics
