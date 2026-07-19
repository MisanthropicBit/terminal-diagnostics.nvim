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

---@class (exact) terminal-diagnostics.ResolvedMatchSpec : terminal-diagnostics.MatchSpec
---@field multiline   boolean
---@field subpatterns string[]

--- A match resulting from matching a pattern with a match spec. Contains no
--- contextual data
---@class terminal-diagnostics.Match
---@field text       string
---@field submatches string[]
---@field from       terminal-diagnostics.Position
---@field to         terminal-diagnostics.Position
---@field spec       terminal-diagnostics.MatchSpec

--- The contextual data extracted from a match using a match spec
---@class (exact) terminal-diagnostics.MatchResult
---@field name     string?
---@field paths    string[]
---@field lnum     integer?
---@field col      integer?
---@field severity string?
---@field code     string?
---@field message  string?

-- TODO: Just embed spec in the match

---@class (exact) terminal-diagnostics.MatchResult2
---@field spec terminal-diagnostics.MatchSpec
---@field match terminal-diagnostics.Match

---@class terminal-diagnostics.MatchAtCursorOptions
---@field buffer integer

---@class terminal-diagnostics.MatchOptions: terminal-diagnostics.MatchAtCursorOptions
---@field count integer?

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
---@return string[]?
local function resolve_path(path, path_kind)
    if not path then
        return
    end

    if not path_kind or path_kind == "relative" then
        -- TODO: Slow for large repos, can we perhaps cache results or
        -- check in relation to the project root?
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
---@return "ERROR" | "WARN" | "INFO" | "HINT"
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

    -- TODO: Allow all keys to support a function for full control
    return {
        paths = resolve_path(submatches[match_spec.path], match_spec.path_kind),
        lnum = resolve_value(match_spec.lnum, submatches, tonumber),
        col = resolve_value(match_spec.col, submatches, tonumber),
        severity = resolve_value(match_spec.severity, submatches, resolve_severity),
        code = submatches[match_spec.code],
        message = submatches[match_spec.message],
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

return matchers
