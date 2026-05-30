---@class terminal-diagnostics.CommandSpec
---@field private _name        string
---@field private _kind        terminal-diagnostics.CommandKind
---@field private _has_context boolean
---@field private _matcher     terminal-diagnostics.Matcher
---@field private _parser      terminal-diagnostics.parser.Parser?
local CommandSpec = {}

-- TODO: Rename kind to tags?
-- TODO: Add parent kind? eslint-compact => eslint?

CommandSpec.__index = CommandSpec

---@class (exact) terminal-diagnostics.CommandSpecOptions
---@field parser      terminal-diagnostics.parser.Parser?
---@field has_context boolean?

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
    -- vim.validate("matcher", matcher, matchers.validator, "a Matcher class instance")
    vim.validate("options.parser", _options.parser, "table", true, "a Parser class instance") -- TODO: Add class validator

    matcher:resolve_specs()

    local command_spec = setmetatable({
        _name = name,
        _kind = kind,
        _has_context = _options.has_context and true or false,
        _matcher = matcher,
        _parser = _options.parser or nil,
    }, CommandSpec)

    command_spec._parser = _options.parser

    if not command_spec._parser then
        command_spec._parser = require("terminal-diagnostics.parsers.simple_parser").new(command_spec)

        -- require("terminal-diagnostics.parsers.generators").from_simple_matcher(command_spec, {})
    end

    command_spec._parser:set_command_spec(command_spec)

    return command_spec
end

---@return string
function CommandSpec:name()
    return self._name
end

---@return terminal-diagnostics.CommandKind
function CommandSpec:kind()
    return self._kind
end

---@return boolean
function CommandSpec:has_context()
    -- TODO: This should be a flag on the parser
    return self._has_context
end

---@return terminal-diagnostics.Matcher
function CommandSpec:matcher()
    return self._matcher
end

---@return terminal-diagnostics.parser.Parser
function CommandSpec:parser()
    return self._parser
end

return CommandSpec
