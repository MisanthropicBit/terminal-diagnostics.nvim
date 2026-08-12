--- Heavily inspired by neotest's subprocess module with two distinct differences:
---
--- 1. It is truly parallel. Neotest starts an asynchronous task in the subprocess
---    which will only yield back to the parent process when it begins executing an
---    asynchronous operation (like treesitter parsing). While this is not a problem
---    in general, code like 'function() vim.uv.sleep(3000) end' would block the
---    parent process for 3 seconds.
--- 2. ...

local log = require("terminal-diagnostics.log")
local notify = require("terminal-diagnostics.notify")

--- Run tasks in parallel using an embedded neovim subprocess
---@class terminal-diagnostics.Subprocess
---@field private _running        boolean
---@field private _child_channel  integer
local Subprocess = {}

Subprocess.__index = Subprocess

--- Channel for the parent neovim process
---@type integer
local parent_channel

--- The address of the parent neovim process
---@type string?
local _parent_address

--- All currently running coroutines for parallel jobs
---@type thread[]
local coroutines = {}

--- Get the address of the parent neovim process
---@return string?
local function get_parent_address()
    if not _parent_address then
        -- Zero is a random port
        _, _parent_address = pcall(vim.fn.serverstart, "localhost:0")
    end

    return _parent_address
end

--- The function that is called from subprocesses when results are ready
---@private
---@param callback_id integer
---@param result      unknown
---@param err         unknown
function Subprocess._register_result(callback_id, result, err)
    log.debug("Result registered for callback", callback_id)

    local co = coroutines[callback_id]

    if not co then
        log.error(
            ("Unexpectedly found no coroutine for callback id %d"):format(callback_id)
        )
        return
    end

    if coroutine.status(co) ~= "suspended" then
        log.error("Coroutine was not in a suspended state")
        return
    end

    coroutines[callback_id] = nil
    local value = err and "Remote callback failed: " .. tostring(err) or result

    -- Resume the coroutine with the result of execution
    coroutine.resume(co, value)
end

--- Check if the current neovim instance is the sub- or parent process
---@private
---@return boolean
function Subprocess._is_child_process()
    -- The parent channel is only set in subprocesses
    return parent_channel ~= nil
end

---@private
---@param parent_address string
---@param child_channel  integer
function Subprocess._set_parent_address(parent_address, child_channel)
    _G._TERMINAL_DIAGNOSTICS_IS_CHILD_PROCESS = true
    local _parent_channel = vim.fn.sockconnect("tcp", parent_address, { rpc = true })

    if _parent_channel == 0 then
        log.error(
            "Failed to connect to parent process at",
            parent_address,
            "for subprocess",
            child_channel
        )

        return
    end

    parent_channel = _parent_channel

    log.debug(
        "Subprocess",
        child_channel,
        "connected to parent process at",
        parent_address,
        "on channel",
        _parent_channel
    )
end

--- Invoke a remote call in the neovim subprocess
---@param func function
---@param callback_id integer
---@param child_channel integer
---@param args any
function Subprocess._remote_call(func, callback_id, child_channel, args)
    log.debug(
        "Subprocess",
        child_channel,
        "received remote call with id",
        callback_id,
        func
    )

    -- Schedule the computation for "later" when the scheduler is ready. This
    -- ensures that we return immediately from a remote call as the rpcrequest
    -- call in the parent process would otherwise block. This isn't an issue
    -- for asynchronous work but if 'func' was 'function() vim.uv.sleep(3000)
    -- end', the parent process would block for 3 seconds
    vim.schedule(function()
        xpcall(function()
            local result = func(unpack(args))

            Subprocess:notify_parent(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.subprocess')._register_result(...)",
                { callback_id, result }
            )
        end, function(msg)
            local err = debug.traceback(msg, 2)

            log.error(
                "Subprocess",
                child_channel,
                "had an error in remote call with id",
                callback_id,
                ":",
                err
            )

            Subprocess:notify_parent(
                "nvim_exec_lua",
                "return require('terminal-diagnostics.subprocess')._register_result(...)",
                { callback_id, nil, err }
            )
        end)
    end)
end

---@return terminal-diagnostics.Subprocess
function Subprocess.new()
    local subprocess = { _running = false }

    return setmetatable(subprocess, Subprocess)
end

--- @param method string
--- @param ... any
function Subprocess:notify_parent(method, ...)
    vim.fn.rpcnotify(parent_channel, method, ...)
end

function Subprocess:start()
    if self:running() then
        notify.log.error("Cannot start, subprocess is already running")
        return
    end

    log.debug("Starting subprocess")

    local parent_address = get_parent_address()

    if not parent_address then
        log.error("Failed to get parent server address", parent_address)
        return
    end

    log.debug("Parent address is", parent_address)
    _parent_address = parent_address

    local command = {
        vim.uv.exepath(),
        "--embed",
        "--headless",
        "-n",
        "-u",
        "NONE",
    }

    log.debug("Starting subprocess with command", table.concat(command, " "))

    local child_channel = vim.fn.jobstart(command, {
        rpc = true,
        on_exit = function()
            log.debug("Subprocess exited")
            self._running = false
        end,
    })

    if child_channel <= 0 then
        log.error("Failed to start subprocess", child_channel)
        return
    end

    self._child_channel = child_channel

    xpcall(function()
        local mode = vim.fn.rpcrequest(child_channel, "nvim_get_mode")

        if mode.blocking then
            log.error("Subprocess is waiting for input at startup. Aborting.")
            return
        end

        local subprocess_rtp =
            vim.fn.rpcrequest(child_channel, "nvim_get_option_value", "runtimepath", {})

        subprocess_rtp = ("%s,%s"):format(subprocess_rtp, vim.fs.abspath("."))

        vim.fn.rpcrequest(
            child_channel,
            "nvim_set_option_value",
            "runtimepath",
            subprocess_rtp,
            {}
        )

        vim.fn.rpcrequest(
            child_channel,
            "nvim_exec_lua",
            "return require('terminal-diagnostics') and 0",
            {}
        )

        vim.fn.rpcrequest(
            child_channel,
            "nvim_exec_lua",
            "return require('terminal-diagnostics.subprocess')._set_parent_address(...)",
            { parent_address, self._child_channel }
        )

        self._running = true

        log.debug("Subprocess", self._child_channel, "is running")
    end, function(msg)
        log.error("Failed to initialize subprocess", debug.traceback(msg, 2))
        self:stop()
    end)
end

function Subprocess:stop()
    if self._child_channel then
        log.debug("Stopping subprocess", self._child_channel)

        xpcall(function()
            vim.fn.chanclose(self._child_channel, "rpc")
            self._running = false
        end, function(msg)
            log.error("Failed to close child channel", msg)
        end)
    end
end

---@return boolean
function Subprocess:running()
    return self._running
end

--- Make a call to the subprocess
---@async
---@param func string function string to execute in the subprocess e.g. 'require("...").my_func'
---@param args any    arguments for the function e.g. '{ 1, 2, 3 }'
---@param callback fun(result: any, err: any)
function Subprocess:call(func, args, callback)
    if not self:running() then
        notify.log.error("Cannot call subprocess before starting it")
        return
    end

    local callback_id = table.maxn(coroutines) + 1

    local co = coroutine.create(function()
        -- Immediately yield this coroutine so it is in a suspended state
        -- before we do the call to the subprocess. This ensures that the
        -- coroutine is ready to be resumed once the call in the subprocess is
        -- done and resume it with the result of execution.
        --
        -- This is important for very fast computations where the subprocess
        -- might try to resume the coroutine before we yielded if we did the
        -- rpcrequest call before yielding
        callback(coroutine.yield())
    end)

    coroutines[callback_id] = co
    coroutine.resume(co)

    local ok, err = pcall(
        vim.fn.rpcrequest,
        self._child_channel,
        "nvim_exec_lua",
        "return require('terminal-diagnostics.subprocess')._remote_call("
        .. func
        .. ", ...)",
        { callback_id, self._child_channel, args or {} }
    )

    if not ok then
        log.error(("Invalid submission to subprocess: %s"):format(err))
        callback(nil, err)
    end
end

return Subprocess
