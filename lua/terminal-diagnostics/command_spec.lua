---@class terminal-diagnostics.CommandSpec
---@field private _name     string
---@field private _kind     terminal-diagnostics.CommandKind
---@field private _matcher terminal-diagnostics.Matcher
---@field private _parser  terminal-diagnostics.parser.Parser?
local CommandSpec = {}

CommandSpec.__index = CommandSpec

---@class (exact) terminal-diagnostics.CommandSpecOptions
---@field parser terminal-diagnostics.parser.Parser?

---@enum terminal-diagnostics.CommandKind
CommandSpec.CommandKind = {
    Build = "build",
    Test = "test",
    Stacktrace = "stacktrace",
    Lint = "lint",
}

---@param name string
---@param kind terminal-diagnostics.CommandKind
---@param matcher terminal-diagnostics.Matcher
---@param options terminal-diagnostics.CommandSpecOptions?
---@return terminal-diagnostics.CommandSpec
function CommandSpec.new(name, kind, matcher, options)
    local _options = options or {}
    local matchers = require("terminal-diagnostics.matchers")

    vim.validate("name", name, "string")
    vim.validate("kind", kind, "string") -- TODO: Add enum validator
    vim.validate("matcher", matcher, matchers.validator, "a Matcher class instance")
    vim.validate("options.parser", _options.parser, "table", true, "a Parser class instance") -- TODO: Add class validator

    return setmetatable({
        _name = name,
        _kind = kind,
        _matcher = matcher,
        _parser = _options.parser or nil,
    }, CommandSpec)
end

---@return terminal-diagnostics.Matcher
function CommandSpec:matcher()
    return self._matcher
end

return CommandSpec
