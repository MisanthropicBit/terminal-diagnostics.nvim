local processor = {}

local builtins = require("terminal-diagnostics.command_specs")
local guess_command = require("terminal-diagnostics.processor.guess_command")
local log = require("terminal-diagnostics.log")
local patterns = require("terminal-diagnostics.patterns")
local Subprocess = require("terminal-diagnostics.subprocess")

local subprocess = Subprocess.new()

---@class terminal-diagnostics.ProcessorOptions
---@field parallel boolean?

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
            for _, match_spec in ipairs(command_spec:matcher():specs()) do
                if match_spec.subpatterns then
                    local lnum = patterns.find_in_lines(output, match_spec)

                    if lnum ~= -1 then
                        table.insert(command_specs, command_spec)
                        break
                    end
                end
            end
        end
    end

    return command_specs
end

--- Must be a module function so it can potentially be called by a subprocess
---@param event   terminal-diagnostics.TerminalRequestEvent
---@param options terminal-diagnostics.ProcessorOptions?
---@return terminal-diagnostics.OutputProcessorResult[]?
---@diagnostic disable-next-line: unused-local
function processor._internal_process(event, options)
    local input, output = event.input, event.output

    -- 1. Attempt to guess the output format from the input command. Otherwise
    --    loop through all builtin command specs and find ones that have a match
    local command_specs = get_command_specs(input, output)

    if #command_specs == 0 then
        log.debug("No viable command specs found for output event", event)
        return
    end

    -- 2. Parse output using all command specs
    local results = {}
    local start_lnum = event.output_range and event.output_range.from.lnum or 0

    ---@type terminal-diagnostics.ParseOptions
    local parse_options = {
        offset = start_lnum,
        extract = true,
    }

    log.timing.start("sequential.parse_results")

    for _, command_spec in ipairs(command_specs) do
        local parser = command_spec:parser()
        local timing_name = ("sequential.parse_results.%s"):format(command_spec:name())

        log.timing.start(timing_name)
        local parse_results = parser:parse(output, parse_options)
        log.timing.stop(timing_name)

        if #parse_results == 0 then
            log.error(
                ("Command spec '%s' did not have any parse results"):format(
                    command_spec:name()
                )
            )
        else
            table.insert(results, {
                command_spec = command_spec,
                parse_results = parse_results,
            })
        end
    end

    log.timing.stop("sequential.parse_results")

    if #results == 0 then
        log.error("Unexpectedly found no results when parsing output")
        return
    end

    -- TODO: Resolve parse results that occupy the same lines

    return results
end

---@async
---@param event    terminal-diagnostics.TerminalRequestEvent
---@param callback fun(value: any)
---@param options  terminal-diagnostics.ProcessorOptions?
---@return terminal-diagnostics.OutputProcessorResult?
function processor.process(event, callback, options)
    local _options = options or {}

    if _options.parallel then
        if not subprocess:running() then
            subprocess:start()

            vim.api.nvim_create_autocmd("VimLeavePre", {
                callback = function()
                    subprocess:stop()
                end,
            })
        end

        subprocess:call(
            "require('terminal-diagnostics.processor')._internal_process",
            { event, _options },
            callback
        )
    else
        local result = processor._internal_process(event, _options)

        callback(result)
    end
end

return processor
