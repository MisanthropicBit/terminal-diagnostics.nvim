---@alias terminal-diagnostics.LogFunc fun(...: unknown)

---@class log
---@field trace terminal-diagnostics.LogFunc
---@field debug terminal-diagnostics.LogFunc
---@field info  terminal-diagnostics.LogFunc
---@field warn  terminal-diagnostics.LogFunc
---@field error terminal-diagnostics.LogFunc
local log = { timing = {} }

local timings = {}
local ordered_timings = {}

log.rotation_strategy = {}

-- local Path = require("terminal-diagnostics.path")

local separator = "|"
local default_log_level = vim.log.levels.WARN
local date_format = "%FT%H:%M:%SZ%z"

local MAX_SIZE_BYTES = 5e+7 -- 50 MB

---@alias terminal-diagnostics.LogRotationStrategy fun(logger: terminal-diagnostics.Logger)

---@return string
local function newline()
    if jit then
        local os = string.lower(jit.os)

        if os == "linux" or os == "osx" or os == "bsd" then
            return "\n"
        else
            return "\r\n"
        end
    else
        return package.config:sub(1, 1)
    end
end

--- Rotation strategy where the same log file is cleared and reused
---@param max_size_bytes integer
---@return terminal-diagnostics.LogRotationStrategy
function log.rotation_strategy.reuse(max_size_bytes)
    return function(logger)
        local stat = vim.uv.fs_stat(tostring(logger:path()))

        if stat and stat.size >= max_size_bytes then
            local handle = logger:handle()
            io.close(handle)

            logger:set_handle(assert(io.open(logger:path(), "a+")))
        end
    end
end

--- Rotation strategy where a new log file is created once the current because
--- too big
---@return terminal-diagnostics.LogRotationStrategy
function log.rotation_strategy.new_file()
    return function(logger)
        -- TODO:
    end
end

---@class terminal-diagnostics.LogOptions
---@field level  vim.log.levels?
---@field path   string?
---@field rotate terminal-diagnostics.LogRotationStrategy?

---@class terminal-diagnostics.Logger
---@field trace terminal-diagnostics.LogFunc
---@field debug terminal-diagnostics.LogFunc
---@field info  terminal-diagnostics.LogFunc
---@field warn  terminal-diagnostics.LogFunc
---@field error terminal-diagnostics.LogFunc
---
---@field private _path string
---@field private _level integer
---@field private _handle file*
---@field private _rotate terminal-diagnostics.LogRotationStrategy
local Logger = {}

Logger.__index = Logger

---@return vim.log.levels
function log.default_level()
    if not default_log_level then
        local env_log_level = vim.fn.getenv("TERMINAL_DIAGNOSTICS_LOG_LEVEL") ~= nil

        if type(env_log_level) == "string" then
            local level_name = vim.log.levels[env_log_level:upper()]

            if level_name then
                default_log_level = level_name
            else
                default_log_level = vim.log.levels.WARN
            end
        else
            default_log_level = vim.log.levels.WARN
        end
    end

    return default_log_level
end

---@param filename string
---@param options terminal-diagnostics.LogOptions?
---@return terminal-diagnostics.Logger
function Logger.new(filename, options)
    local _options = options or {}
    local path

    if _options.path then
        path = _options.path
    else
        path = vim.fs.joinpath(vim.fn.stdpath("log"), filename) .. ".log"
    end

    ---@cast path -nil
    local handle = assert(io.open(path, "a+"))

    ---@type terminal-diagnostics.Logger
    ---@diagnostic disable-next-line: missing-fields
    local logger = {
        _path = path,
        _level = _options.level or default_log_level,
        _handle = handle,
        _rotate = _options.rotate or log.rotation_strategy.reuse(MAX_SIZE_BYTES),
    }

    for level_name, level in pairs(vim.log.levels) do
        local _name = level_name:lower()

        if level ~= vim.log.levels.OFF then
            ---@diagnostic disable-next-line: assign-type-mismatch
            logger[_name] = function(...)
                Logger.log(logger, level_name, ...)
            end
        end
    end

    return setmetatable(logger, Logger)
end

---@private
function Logger:log(level_name, ...)
    if self:level() < log.default_level() then
        return false
    end

    local argc = select("#", ...)

    if argc == 0 then
        return true
    end

    local info = debug.getinfo(4, "Sl")
    local fileinfo = ("%s:%s"):format(info.source:sub(1), info.currentline)
    local parts = {
        table.concat({
            level_name,
            separator,
            os.date(date_format),
            separator,
            fileinfo,
            separator,
        }, " "),
    }

    for idx = 1, argc do
        local arg = select(idx, ...)

        if arg == nil then
            table.insert(parts, "<nil>")
        elseif type(arg) == "string" then
            table.insert(parts, arg)
        elseif type(arg) == "table" and vim.is_callable(arg.__tostring) then
            table.insert(parts, arg.__tostring(arg))
        else
            table.insert(parts, vim.inspect(arg))
        end
    end

    self._rotate(self)

    -- TODO: When should this be closed? Does it close itself when quitting neovim?
    self._handle:write(table.concat(parts, " "), newline())
    self._handle:flush()
end

---@return string
function Logger:path()
    return self._path
end

---@return integer
function Logger:level()
    return self._level
end

---@package
---@return file*
function Logger:handle()
    return self._handle
end

---@package
---@param handle file*
function Logger:set_handle(handle)
    self._handle = handle
end

local default_logger = Logger.new("terminal-diagnostics")

---@return terminal-diagnostics.Logger
function log.default_logger()
    return default_logger
end

---@param name string
---@return terminal-diagnostics.Logger
function log.with_context(name)
    local wrapper = setmetatable({}, { __index = default_logger })

    for level_name, level in pairs(vim.log.levels) do
        local _name = level_name:lower()

        if level ~= vim.log.levels.OFF then
            ---@diagnostic disable-next-line: assign-type-mismatch
            wrapper[_name] = function(...)
                Logger.log(default_logger, level_name, name, ...)
            end
        end
    end

    return wrapper
end

---@param data string | table<string, unknown>
function log.timing.start(data)
    local _data = type(data) == "string" and { name = data } or data
    ---@cast _data table<string, unknown>

    timings[_data.name] = {
        data = _data,
        start_time = vim.uv.hrtime(),
    }

    table.insert(ordered_timings, _data.name)
end

---@param name string?
function log.timing.stop(name)
    local timing

    if name then
        timing = timings[name]

        if not timing then
            error(("No timing found with name '%s'"):format(name))
        end

        timings[name] = nil
    else
        local last_name = ordered_timings[#ordered_timings]
        timing = timings[last_name]

        if not timing then
            error("No timing found, did you forget to call log.timing.start?")
        end

        timings[last_name] = nil
    end

    table.remove(ordered_timings)
    local elapsed_ms = vim.uv.hrtime() - timing.start_time

    log.debug("timing", timing, ("elapsed ms: %.2f"):format(elapsed_ms))
end

---@package
--- Only used in testing
function log.timing.clear()
    timings = {}
    ordered_timings = {}
end

for level_name, level in pairs(vim.log.levels) do
    if level ~= vim.log.levels.OFF then
        local _level_name = level_name:lower()

        log[_level_name] = function(...)
            default_logger[_level_name](...)
        end
    end
end

return log
