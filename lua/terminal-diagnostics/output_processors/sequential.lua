local SequentialOutputProcessor = {}

local builtins = require("terminal-diagnostics.builtins")
local diagnostics = require("terminal-diagnostics.diagnostics")
local guess_command = require("terminal-diagnostics.output_processors.guess_command")
local log = require("terminal-diagnostics.log")
local notify = require("terminal-diagnostics.notify")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.SequentialOutputProcessorOptions
---@field terminal_diagnostics boolean?
---@field diagnostics          boolean?
---@field quickfix             boolean?
---@field locationlist         boolean?

-- TODO: Emit autocmd events after processing
-- TODO: Create clickable links for error codes?

SequentialOutputProcessor.__index = SequentialOutputProcessor

---@param input string[]?
---@param output string[]
---@return terminal-diagnostics.CommandSpec[]
local function get_command_specs(input, output)
    local command_specs = {}
    local guessed_command_spec = guess_command.guess(input)

    if guessed_command_spec then
        command_specs = { guessed_command_spec }
    else
        local builtin_command_specs = builtins.get()

        for _, command_spec in ipairs(builtin_command_specs) do
            for _, match_spec in ipairs(command_spec:matcher().specs()) do
                local lnum = utils.patterns.find_in_lines(output, match_spec)

                if lnum ~= -1 then
                    table.insert(command_specs, command_spec)
                    break
                end
            end
        end
    end

    return command_specs
end

function SequentialOutputProcessor.new()
    return setmetatable({}, SequentialOutputProcessor)
end

---@param event   terminal-diagnostics.TerminalOutputEvent
---@param options terminal-diagnostics.SequentialOutputProcessorOptions?
function SequentialOutputProcessor.process(event, options)
    local _options = options or {}

    if not _options.terminal_diagnostics and not _options.diagnostics and not _options.quickfix then
        return
    end

    local input = event.input
    local output = event.output

    -- 1. Attempt to guess the output format from the input command. Otherwise
    --    loop through all builtin command specs and find ones that have a match
    local command_specs = get_command_specs(input, output)

    if #command_specs == 0 then
        return
    end

    -- 2. Parse output using all command specs
    local parse_results = {}

    for _, command_spec in ipairs(command_specs) do
        local parser = command_spec:parser()
        local _parse_results = parser.parse(output)

        if #_parse_results == 0 then
            log.error(("Command spec '%s' did not have any parse results"):format(command_spec:name()))
        else
            vim.list_extend(parse_results, _parse_results)
        end
    end

    if #parse_results == 0 then
        notify.error("Unexpectedly found no results when parsing output")
        return
    end

    -- 3. Create terminal diagnostics from parse results
    if _options.terminal_diagnostics then
        local terminal_diagnostics = diagnostics.terminal_from_parse_results(parse_results)

        diagnostics.set(event.buffer, terminal_diagnostics, {})
    end

    -- 4. Create diagnostics for the project from parse results
    if _options.diagnostics then
        local all_diagnostics = diagnostics.from_parse_results(parse_results)

        -- TODO: Need to resolve paths to absolute paths and load the buffers
        -- for those files. Alternatively, set diagnostics for the buffers that
        -- are already open and cache the rest. When a new buffer is opened,
        -- check if the filename matches, set diagnostics, and clear cache entry
        -- (what if the buffer is unloaded and then loaded again?)
        diagnostics.set(0, all_diagnostics, {})
    end

    -- 4. Populate the quickfix/location list with the diagnostics (let user do this via autocmds?)
    if _options.quickfix or _options.locationlist then
        -- TODO: Do we add the terminal diagnostics or the ordinary diagnostics
        -- to the lists?
        local sources = vim.tbl_map(function(spec)
            return spec:name()
        end, command_specs)

        -- local qf_items = vim.diagnostic.toqflist()

        diagnostics.setqflist({
            open = true,
            namespace = diagnostics.namespace_id(),
            title = ("terminal-diagnostics.nvim (%s)"):format(vim.iter(sources):join(", ")),
        })
    end

    -- 5. Optionally notify the user
    -- notify.info("Processed terminal output")

    -- vim.api.nvim_exec_autocmds("User", {
    --     pattern = "terminal-diagnostics.processor.completed",
    --     modeline = false,
    --     data = { event = event },
    -- })
end

return SequentialOutputProcessor
