local builtin_command_specs = require("terminal-diagnostics.command_specs")
local guess_command = require("terminal-diagnostics.output_processors.guess_command")
local log = require("terminal-diagnostics.log")
local patterns = require("terminal-diagnostics.patterns")

---@class terminal-diagnostics.OutputProcessorResult
---@field parse_results terminal-diagnostics.parser.ParseResult[]
---@field command_specs terminal-diagnostics.CommandSpec[]

---@class terminal-diagnostics.OutputProcessor
local OutputProcessor = {}

OutputProcessor.__index = OutputProcessor

function OutputProcessor:start()
    error("start method not implemented")
end

function OutputProcessor:stop()
    error("stop method not implemented")
end

---@return boolean
function OutputProcessor:running()
    error("running method not implemented")
end

---@param event   terminal-diagnostics.TerminalOutputEvent
---@param options terminal-diagnostics.SequentialOutputProcessorOptions?
---@diagnostic disable-next-line: unused-local
function OutputProcessor:process(event, options)
    error("process method not implemented")
end

---@protected
---@param input  string[]?
---@param output string[]
---@return terminal-diagnostics.CommandSpec[]
function OutputProcessor.get_command_specs(input, output)
    local command_specs = {}
    local guessed_command_spec = guess_command.guess(input)

    if guessed_command_spec then
        command_specs = { guessed_command_spec }
    else
        local builtins = builtin_command_specs.get()

        for _, command_spec in ipairs(builtins) do
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

---@protected
---@param output        string[]
---@param command_specs terminal-diagnostics.CommandSpec[]
---@param parse_options terminal-diagnostics.ParseOptions
---@return terminal-diagnostics.parser.ParseResult[]
function OutputProcessor.parse(output, command_specs, parse_options)
    local parse_results = {} ---@type terminal-diagnostics.parser.ParseResult[]

    for _, command_spec in ipairs(command_specs) do
        local parser = command_spec:parser()

        -- log.timing.start(("sequential.parse_results.%s"):format(command_spec:name()))
        local _parse_results = parser:parse(output, parse_options)
        -- log.timing.stop()

        if #_parse_results == 0 then
            log.error(("Command spec '%s' did not have any parse results"):format(command_spec:name()))
        else
            vim.list_extend(parse_results, _parse_results)
        end
    end

    return parse_results
end

return OutputProcessor
