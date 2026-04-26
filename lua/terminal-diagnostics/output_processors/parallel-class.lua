--- Heavily inspired by neotest's subprocess module and mini.test's child class

local log = require("terminal-diagnostics.log")

--- Run tasks in parallel using an embedded neovim child process
---@class terminal-diagnostics.Parallel
---@field private _running boolean
---@field private _channel integer
local Parallel = {}

Parallel.__index = Parallel

---@type thread[]
local coroutines = {}

---@type string?
local _parent_address

--- Get the address of the parent neovim process
---@return string?
local function get_parent_address()
    if not _parent_address then
        local server_ok
        server_ok, _parent_address = pcall(vim.fn.serverstart, "localhost:0")

        if not server_ok then
            log.error("Failed to get parent server address: " .. _parent_address)
            return
        end
    end

    return _parent_address
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
---@param result         unknown
---@param err         unknown
local function register_result(callback_id, result, err)
    log.debug("Result registed for callback", callback_id)

    local co = coroutines[callback_id]
    coroutines[callback_id] = nil
    local value = err and "Parallel callback failed: " .. tostring(err) or result

    coroutine.resume(co, value)
end

function Parallel._remote_call(func, cb_id, args)
    log.info("Received remote call", cb_id, func)

    vim.schedule(function()
        xpcall(function()
            local result = func(unpack(args))

            notify(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.parallel')._register_result(...)",
                { cb_id, result }
            )
        end, function(msg)
            local err = debug.traceback(msg, 2)

            log.warn("Error in remote call", err)

            notify(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.parallel')._register_result(...)",
                { cb_id, nil, err }
            )
        end)
    end)
end

---@return terminal-diagnostics.Parallel
function Parallel.new()
    local parallel = {
        _running = false,
        _channel = nil,
    }

    return setmetatable(parallel, Parallel)
end

function Parallel:start()
    log.info("Starting embedded neovim process")

    local parent_address = get_parent_address()

    if not parent_address then
        log.error("Failed to get parent server address: " .. parent_address)
        return
    end

    log.info("Parent address: " .. parent_address)

    local cmd = {
        vim.uv.exepath(),
        "--embed",
        "--headless",
        "-n",
        "-u",
        "NONE",
    }

    log.info("Starting child process with command: " .. table.concat(cmd, " "))

    local start_ok, child_chan = pcall(vim.fn.jobstart, cmd, {
        rpc = true,
        on_exit = function()
            log.info("Child process exited")
            self._running = false
        end,
    })

    if not start_ok then
        log.error("Failed to start child process", child_chan)
        return
    end

    self._channel = child_chan

    xpcall(function()
        local mode = vim.fn.rpcrequest(child_chan, "nvim_get_mode")

        if mode.blocking then
            log.error("Child process is waiting for input at startup. Aborting.")
            return
        end

        -- local to_add = { require("terminal-diagnostics").setup }

        -- neotest.lib.subprocess.add_to_rtp(to_add)

        vim.fn.rpcrequest(
            child_chan,
            "nvim_exec_lua",
            "return require('terminal-diagnostics') and 0",
            {}
        )

        vim.fn.rpcrequest(
            child_chan,
            "nvim_exec_lua",
            "return require('terminal-diagnostics.parallel')._set_parent_address(...)",
            { _parent_address }
        )

        vim.api.nvim_create_autocmd("VimLeavePre", {
            callback = function()
                self:stop()
            end,
        })
    end, function(msg)
        log.error("Failed to initialize child process", debug.traceback(msg, 2))
        self:stop()
    end)
end

function Parallel:stop()
    if self._channel then
        log.info("Closing child channel")

        xpcall(function()
            vim.fn.chanclose(self._channel, "rpc")
        end, function(msg)
            log.error("Failed to close child channel: " .. msg)
        end)
    end
end

function Parallel:running()
    return self._running
end

---@async
function Parallel:submit(func, args, callback)
    local co = coroutine.create(function()
        local _, err = pcall(
            request,
            "nvim_exec_lua",
            "return require('terminal-diagnostics.output_processors.parallel')._remote_call("
            .. func
            .. ", ...)",
            { cb_id, args or {} }
        )

        assert(not err, ("Invalid submission: %s"):format(err))

        callback(coroutine.yield())
    end)

    coroutine.resume(co)
end

return Parallel
