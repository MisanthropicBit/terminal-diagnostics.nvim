local minitest = require("mini.test")
local Subprocess = require("terminal-diagnostics.subprocess")

local new_set = minitest.new_set
local eq = minitest.expect.equality
local err = minitest.expect.error

local child = minitest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_case = function()
            child.restart()
        end,
        post_once = child.stop,
    },
})

T["Subprocess"] = new_set()

T["Subprocess"]["calls subprocess and gets result"] = function()
end

T["Subprocess"]["subprocess is truly parallel"] = function()
end

T["Subprocess"]["fails to start if already running"] = function()
    local subprocess = Subprocess.new()

    subprocess:start()
    eq(subprocess:running(), true)

    err(function()
        subprocess:start()
    end, "Cannot start, subprocess is already running")
end

T["Subprocess"]["fails to call subprocess before starting"] = function()
    local subprocess = Subprocess.new()

    err(function()
        subprocess:call("function() return 1 + 2 end", nil, function() end)
    end, "Cannot call subprocess before starting it")
end

return T
