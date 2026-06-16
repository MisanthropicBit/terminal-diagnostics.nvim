local new_set = MiniTest.new_set
local eq, has_error = MiniTest.expect.equality, MiniTest.expect.error

local log = require("terminal-diagnostics.log")

local T = new_set({
    hooks = {
        pre_case = function()
            ---@diagnostic disable-next-line: invisible
            log.timing.clear()
        end,
    },
})

T["log"] = new_set()
T["log"]["timing"] = new_set()

T["log"]["timing"]["times a section of code"] = function()
    log.timing.start({ name = "test", tag = "perf" })
    log.timing.stop("test")
end

T["log"]["timing"]["times a section of code without specifying name when stopping"] = function()
    log.timing.start({ name = "test", tag = "perf" })
    log.timing.stop()
end

T["log"]["timing"]["fails if name not found"] = function()
    has_error(function()
        log.timing.start("test")
        log.timing.stop("some-name")
    end, "No timing found with name 'some%-name'")
end

T["log"]["timing"]["fails if log.timing.start was not called"] = function()
    has_error(function()
        log.timing.stop()
    end, "No timing found, did you forget to call log.timing.start?")
end

return T
