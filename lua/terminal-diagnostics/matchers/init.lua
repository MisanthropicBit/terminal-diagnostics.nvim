local matchers = {}

---@generic T: string, integer
---@class (exact) terminal-diagnostics.SpecKeyResolver<T>
---@field index   integer
---@field resolve fun(severity: string): T

---@class (exact) terminal-diagnostics.SeverityResolver
---@field index   integer
---@field resolve fun(severity: string): vim.diagnostic.Severity

-- TODO: Add support for end_lnum and end_col
--- A spec for how to match an error and what information capture groups contain
---@class (exact) terminal-diagnostics.MatchSpec
---@field pattern   string
---@field path      integer?
---@field path_kind ("relative" | "absolute")?
---@field lnum      integer?
---@field col       integer?
---@field severity  (integer | terminal-diagnostics.SeverityResolver)?
---@field code      integer?
---@field message   integer?

---@class (exact) terminal-diagnostics.MatchResult
---@field name     string?
---@field paths    string[]
---@field lnum     integer?
---@field col      integer?
---@field severity string?
---@field code     string?
---@field message  string?

---@class terminal-diagnostics.MatchAtCursorOptions
---@field buffer integer

---@class terminal-diagnostics.MatchOptions: terminal-diagnostics.MatchAtCursorOptions
---@field lnum  integer
---@field col   integer
---@field count integer?

---@class terminal-diagnostics.Matcher
---@field match fun(options: terminal-diagnostics.MatchOptions): terminal-diagnostics.Match?, terminal-diagnostics.MatchResult?
---@field match_start fun(options: terminal-diagnostics.MatchOptions): terminal-diagnostics.Match?
---@field match_at_cursor fun(options: terminal-diagnostics.MatchAtCursorOptions): terminal-diagnostics.Match?, terminal-diagnostics.MatchResult?
---@field specs fun(): terminal-diagnostics.MatchSpec[]

local supported_matchers = {}

local cached_matchers

---@enum terminal-diagnostics.MatchSpecKind
matchers.MatchSpecKind = {
    Simple = "simple",
    Header = "header",
}

---@generic T
---@param idx (integer | { index: integer, resolve: fun(value: any): T })?
---@param submatches string[]
---@param type_converter (fun(value: unknown): T)?
---@return T?
local function resolve_value(idx, submatches, type_converter)
    if not idx then
        return
    end

    local _idx, resolver

    if type(idx) == "number" then
        _idx = idx
        resolver = type_converter
    else
        _idx = idx.index
        resolver = idx.resolve
    end

    local value = submatches[_idx]

    if type(resolver) == "function" then
        return resolver(value)
    end

    return value
end

---@param path string
---@param path_kind string?
local function resolve_path(path, path_kind)
    if not path then
        return {}
    end

    if not path_kind or path_kind == "relative" then
        local paths = vim.fs.find(path, {
            limit = math.huge,
            upward = false,
            type = "file",
            -- path = "", TODO: Should be the project root
        })

        return paths
    elseif path_kind == "absolute" then
        return { path }
    end
end

---@param severity string
---@return vim.diagnostic.Severity
local function resolve_severity(severity)
    if not severity then
        return "INFO"
    end

    local uc_severity = severity:upper()
    local direct_value = vim.diagnostic.severity[uc_severity]

    if direct_value then
        return direct_value
    end

    if uc_severity == "WARNING" then
        return vim.diagnostic.severity[2]
    elseif uc_severity == "CRITICAL" then
        return vim.diagnostic.severity[1]
    end

    return "INFO"
end

---@param match_spec terminal-diagnostics.MatchSpec
---@param match terminal-diagnostics.Match
---@return terminal-diagnostics.MatchResult
function matchers.extract_from_match(match_spec, match)
    local submatches = match.submatches

    -- TODO: Account for cases where only a path is known but no position
    -- TODO: Allow all keys to support a function for full control
    return {
        paths = resolve_path(submatches[match_spec.path], match_spec.path_kind),
        lnum = resolve_value(match_spec.lnum, submatches, tonumber),
        col = resolve_value(match_spec.col, submatches, tonumber),
        severity = resolve_value(match_spec.severity,submatches, resolve_severity),
        code = submatches[match_spec.code],
        message = submatches[match_spec.message],
    }
end

---@param filter string[]?
---@return terminal-diagnostics.Matcher[]
function matchers.get_all(filter)
    -- Many of the patterns were borrowed and modified from stevearc/overseer.nvim and ej-shafran/compile-mode.nvim
    return {
        require("terminal-diagnostics.builtins.tsc"),
        -- require("terminal-diagnostics.builtins.eslint-compact"),
        -- require("terminal-diagnostics.builtins.eslint-stylish"),
        -- require("terminal-diagnostics.builtins.jest"),
        -- require("terminal-diagnostics.builtins.python-stacktrace"),
        -- require("terminal-diagnostics.builtins.pytest"),
        -- require("terminal-diagnostics.builtins.gcc"),
        -- require("terminal-diagnostics.builtins.lua-stacktrace"),
        -- require("terminal-diagnostics.builtins.rustc"),
    }
end

---@param spec terminal-diagnostics.MatchSpec
---@return boolean
function matchers.spec_has_info(spec)
    local has_info = spec.path
        or spec.lnum
        or spec.col
        or spec.severity
        or spec.code
        or spec.message

    return has_info ~= nil
end

---@return string[]
function matchers.match_spec_keys()
    return { "path", "lnum", "col", "severity", "code", "message" }
end

---@param value unknown
---@return boolean
function matchers.validator(value)
    if type(value) ~= "table" then
        return false
    end

    -- if type(value.kind) ~= "function" then
    --     return false
    -- end

    if type(value.match) ~= "function" then
        return false
    end

    if type(value.match_start) ~= "function" then
        return false
    end

    if type(value.match_at_cursor) ~= "function" then
        return false
    end

    return true
end

return matchers
