local Subprocess = require("terminal-diagnostics.subprocess")

--- Run tasks in parallel using an embedded neovim child process
---@class terminal-diagnostics.ParallelProcessor : terminal-diagnostics.OutputProcessor
---@field private _subprocess     terminal-diagnostics.Subprocess
local ParallelProcessor = {}

ParallelProcessor.__index = ParallelProcessor

function ParallelProcessor._process(self, event)
    local command_specs = self:get_command_specs(event.output)
    local start_lnum = event.output_pos and event.output_pos.from.lnum or 0
    local parse_results = self:parse(command_specs, {
        extract = true,
        offset = start_lnum,
    })

    return {
        parse_results = parse_results,
        command_specs = command_specs,
    }
end

---@return terminal-diagnostics.ParallelProcessor
function ParallelProcessor.new()
    local parallel = {
        _subprocess = Subprocess.new(),
    }

    return setmetatable(parallel, ParallelProcessor)
end

function ParallelProcessor:start()
    self._subprocess:start()
end

function ParallelProcessor:stop()
    self._subprocess:stop()
end

function ParallelProcessor:running()
    return self._subprocess:running()
end

function ParallelProcessor:process(event, callback)
    self._subprocess:call(
        "require('terminal-diagnostics.output_processors.parallel')._process",
        { self, event },
        function(result, err)
            callback(result, err)
        end
    )
end

return ParallelProcessor
