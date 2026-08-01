--- Heavily inspired by neotest's subprocess module and mini.test's child class

local diagnostics = require("terminal-diagnostics.diagnostics")
local log = require("terminal-diagnostics.log")

--- Run tasks in parallel using an embedded neovim child process
---@class terminal-diagnostics.ParallelProcessor : terminal-diagnostics.OutputProcessor
---@field private _running        boolean
---@field private _channel        integer
---@field private _coroutines     thread[]
---@field private _parent_address string?
local ParallelProcessor = {}

ParallelProcessor.__index = ParallelProcessor

---@type integer, integer
local parent_channel, child_channel

--- All currently running coroutines for parallel jobs
---@type thread[]
local coroutines = {}

--- The address of the parent neovim process
---@type string?
local _parent_address

--- Get the address of the parent neovim process
---@return string?
local function get_parent_address()
    if not _parent_address then
        -- Zero is a random port
        _, _parent_address = pcall(vim.fn.serverstart, "localhost:0")
    end

    return _parent_address
end

---@return integer
local function get_channel()
    if ParallelProcessor._is_child_process() then
        return parent_channel
    else
        return child_channel
    end
end

--- Wrapper around vim.fn.rpcrequest that will automatically select the channel
--- for the child or parent process, depending on if the current instance is the
--- child or parent. See `:help rpcrequest` for more information.
--- @param method string
--- @param ... any
local function request(method, ...)
    vim.fn.rpcrequest(get_channel(), method, ...)
end

--- Wrapper around vim.fn.rpcnotify that will automatically select the channel
--- for the child or parent process, depending on if the current instance is the
--- child or parent. See `:help rpcnotify` for more information.
--- @param method string
--- @param ... any
local function notify(method, ...)
    vim.fn.rpcnotify(get_channel(), method, ...)
end

---@param callback_id integer
---@param result      unknown
---@param err         unknown
function ParallelProcessor._register_result(callback_id, result, err)
    log.debug("Result registered for callback", callback_id)

    local co = coroutines[callback_id]

    if not co then
        log.error(
            ("Unexpectedly found no coroutine for callback id %d"):format(callback_id)
        )
        return
    end

    coroutines[callback_id] = nil
    local value = err and "Remote callback failed: " .. tostring(err) or result

    coroutine.resume(co, value)
end

--- Check if the current neovim instance is the child or parent process
---@private
---@return boolean
function ParallelProcessor._is_child_process()
    return parent_channel ~= nil
end

---@private
---@parent_address string
function ParallelProcessor._set_parent_address(parent_address)
    _G._TERMINAL_DIAGNOSTICS_IS_CHILD_PROCESS = true

    parent_channel = vim.fn.sockconnect("tcp", parent_address, { rpc = true })

    log.info(("Connected to parent process at %s"):format(parent_address))
end

--- Invoke a remote call in the child neovim process
---@param func function
---@param callback_id integer
---@param args any
function ParallelProcessor._remote_call(func, callback_id, args)
    log.info("Received remote call", callback_id, func)

    vim.schedule(function()
        xpcall(function()
            local result = func(unpack(args))

            notify(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.parallel')._register_result(...)",
                { callback_id, result }
            )
        end, function(msg)
            local err = debug.traceback(msg, 2)

            log.warn("Error in remote call", err)

            notify(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.parallel')._register_result(...)",
                { callback_id, nil, err }
            )
        end)
    end)
end

---@return terminal-diagnostics.ParallelProcessor
function ParallelProcessor.new()
    local parallel = {
        _running = false,
        _channel = nil,
    }

    return setmetatable(parallel, ParallelProcessor)
end

function ParallelProcessor:start()
    log.info("Starting embedded neovim process")

    local parent_address = get_parent_address()

    if not parent_address then
        log.error("Failed to get parent server address: " .. parent_address)
        return
    end

    log.info("Parent address: " .. parent_address)

    local command = {
        vim.uv.exepath(),
        "--embed",
        "--headless",
        "-n",
        "-u",
        "NONE",
    }

    log.info("Starting child process with command: " .. table.concat(command, " "))

    local start_ok, child_channel = pcall(vim.fn.jobstart, command, {
        rpc = true,
        on_exit = function()
            log.info("Child process exited")
            self._running = false
        end,
    })

    if not start_ok then
        log.error("Failed to start child process", child_channel)
        return
    end

    self._channel = child_channel

    xpcall(function()
        local mode = vim.fn.rpcrequest(child_channel, "nvim_get_mode")

        if mode.blocking then
            log.error("Child process is waiting for input at startup. Aborting.")
            return
        end

        -- local to_add = { require("terminal-diagnostics").setup }

        -- neotest.lib.subprocess.add_to_rtp(to_add)

        vim.fn.rpcrequest(
            child_channel,
            "nvim_exec_lua",
            "return require('terminal-diagnostics') and 0",
            {}
        )

        vim.fn.rpcrequest(
            child_channel,
            "nvim_exec_lua",
            "return require('terminal-diagnostics.output_processors.parallel')._set_parent_address(...)",
            { _parent_address }
        )
    end, function(msg)
        log.error("Failed to initialize child process", debug.traceback(msg, 2))
        self:stop()
    end)
end

function ParallelProcessor:stop()
    if self._channel then
        log.info("Stopping neovim process")

        xpcall(function()
            vim.fn.chanclose(self._channel, "rpc")
        end, function(msg)
            log.error("Failed to close child channel: " .. msg)
        end)
    end
end

function ParallelProcessor:running()
    return self._running
end

---@async
---@param func function
---@param args any
---@param callback fun(value: any)
function ParallelProcessor:submit(func, args, callback)
    local callback_id = table.maxn(coroutines) + 1

    local co = coroutine.create(function()
        local _, err = pcall(
            request,
            "nvim_exec_lua",
            "return require('terminal-diagnostics.output_processors.parallel')._remote_call("
            .. func
            .. ", ...)",
            { callback_id, args or {} }
        )

        assert(not err, ("Invalid submission to child process: %s"):format(err))

        callback(coroutine.yield())
    end)

    coroutines[callback_id] = co

    coroutine.resume(co)
end

function ParallelProcessor:process(event, options)
    local _options = options or {}

    if not _options.terminal_diagnostics and not _options.diagnostics and not _options.quickfix then
        return
    end

    local input, output = event.input, event.output
    local command_specs = self.get_command_specs(input, output)
    local start_lnum = event.output_pos and event.output_pos.from.lnum or 0
    local extract = (_options.locationlist
            or _options.quickfix
            or _options.trouble
            or _options.terminal_diagnostics) and true or false

    ---@type terminal-diagnostics.ParseOptions
    local parse_options = {
        offset = start_lnum,
        extract = extract,
    }

    self:submit(function()
        return self.parse(output, command_specs, parse_options)
    end, {}, function(parse_results)
        if _options.terminal_diagnostics then
            local terminal_diagnostics = diagnostics.terminal_from_parse_results(parse_results)

            diagnostics.set(event.buffer, terminal_diagnostics, {})
        end
    end)
end

return ParallelProcessor
