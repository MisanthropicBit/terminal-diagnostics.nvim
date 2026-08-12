local matchers = {}

---@alias terminal-diagnostics.VimDiagnosticSeverity "ERROR" | "WARN" | "INFO" | "HINT"

---@generic T: string, integer
---@class (exact) terminal-diagnostics.SpecKeyResolver<T>
---@field index   integer
---@field resolve fun(severity: string): T

---@class (exact) terminal-diagnostics.SeverityResolver
---@field index   integer
---@field resolve fun(severity: string): terminal-diagnostics.VimDiagnosticSeverity

-- TODO: Add support for end_lnum and end_col

--- A spec for how to match an error and what information capture groups contain
---@class (exact) terminal-diagnostics.MatchSpec
---@field pattern     string
---@field path        integer?
---@field path_kind   ("relative" | "absolute")?
---@field lnum        integer?
---@field col         integer?
---@field severity    (integer | terminal-diagnostics.SeverityResolver)?
---@field code        integer?
---@field message     integer?
---@field subpatterns string[]?

---@class (exact) terminal-diagnostics.ResolvedMatchSpec : terminal-diagnostics.MatchSpec
---@field multiline   boolean
---@field subpatterns string[]

--- A match resulting from matching a pattern with a match spec. Contains no
--- contextual data
---@class terminal-diagnostics.Match
---@field text       string
---@field submatches string[]
---@field range      terminal-diagnostics.Range
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

    if path_kind == "absolute" then
        return { path }
    elseif not path_kind or path_kind == "relative" then
        local cwd = vim.fn.getcwd()
        local rel_path = vim.fn.fnamemodify(("%s/%s"):format(cwd, path), ":p")

        return { rel_path }

        -- -- TODO: Slow for large repos, can we perhaps cache results or
        -- -- check in relation to the project root?
        -- local paths = vim.fs.find(path, {
        --     limit = math.huge,
        --     upward = false,
        --     type = "file",
        --     -- path = "", TODO: Should be the project root
        -- })
        --
        -- return paths
    end
end

---@param severity string
---@return terminal-diagnostics.VimDiagnosticSeverity
local function resolve_severity(severity)
    if not severity then
        return "INFO"
    end

    local upper_severity = severity:upper()
    local existing_severity = vim.diagnostic.severity[upper_severity]

    if existing_severity then
        return upper_severity
    elseif upper_severity == "WARNING" then
        return "WARN"
    elseif upper_severity == "CRITICAL" then
        return "ERROR"
    end

    return "INFO"
end

---@param match terminal-diagnostics.Match
---@return terminal-diagnostics.MatchResult
function matchers.extract_from_match(match)
    local match_spec = match.spec
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

---@param maybe_index integer | terminal-diagnostics.SeverityResolver
---@return integer
function matchers.resolve_spec_index(maybe_index)
    return type(maybe_index) == "number" and maybe_index or maybe_index.index
end

---@return string[]
function matchers.match_spec_keys()
    return { "path", "lnum", "col", "severity", "code", "message" }
end

return matchers
