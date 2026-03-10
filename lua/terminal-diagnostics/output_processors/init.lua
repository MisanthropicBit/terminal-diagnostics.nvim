local output_processors = {}

---@class terminal-diagnostics.OutputProcessorOptions
---@field terminal_diagnostics boolean? Generate diagnostics for the terminal buffer
---@field diagnostics          boolean? Generate diagnostics for the project based on the parsed error output
---@field quickfix             boolean? Generate entries for the quickfix list
---@field locationlist         boolean? Generate entries for the location list

function output_processors.get()
end

return output_processors
