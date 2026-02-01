local patterns = {}

---@enum terminal-diagnostics.PatternKind
local PatternKind = {
    Build = "build",
    Test = "test",
    Stacktrace = "stacktrace",
    Lint = "lint",
}

---@class terminal-diagnostics.Pattern
---@field name      string
---@field kind      terminal-diagnostics.PatternKind
---@field regex     string
---@field path      integer?
---@field path_kind ("absolute" | "relative" | "unknown")?
---@field lnum      integer?
---@field col       integer?
---@field severity  integer?
---@field code      integer?
---@field message   integer?
---@field priority  integer?

---@class terminal-diagnostics.MatchSpec
---@field name     string?
---@field regex    string
---@field path     integer?
---@field lnum     integer?
---@field col      integer?
---@field severity integer?
---@field code     integer?
---@field message  integer?

---@class terminal-diagnostics.MatchResult
---@field name     string?
---@field path     string
---@field lnum     integer?
---@field col      integer?
---@field severity string?
---@field code     string?
---@field message  string?

-- Borrowed and modified from stevearc/overseer.nvim and ej-shafran/compile-mode.nvim
---@type table<string, terminal-diagnostics.Pattern[]>
local default_patterns = {
    tsc = {
        {
            name = "tsc",
            kind = PatternKind.Build,
            regex =
            "\\v^([^[:space:]].*)[\\(:](\\d+)[,:](\\d+)%(\\):\\s+|\\s+-\\s+)(error|warning|info)\\s+TS(\\d+)\\s*:\\s*(.*)$",
            path_kind = "relative",
            path = 1,
            lnum = 2,
            col = 3,
            severity = 4,
            code = 5,
            message = 6,
        },
    },
    ["eslint-compact"] = {
        {
            name = "eslint",
            kind = PatternKind.Lint,
            regex = "^(.+):\\sline\\s(\\d+),\\scol\\s(\\d+),\\s(Error|Warning|Info)\\s-\\s(.+)\\s\\((.+)\\)$",
            path = 1,
            lnum = 2,
            col = 3,
            severity = 4,
            message = 5,
            code = 6,
        },
    },
    ["eslint-stylish"] = {
        name = "eslint",
        kind = PatternKind.Lint,
        patterns = {
            {
                -- regex = "^((?:[a-zA-Z]:)*[./\\\\]+.*?)$",
                regex = "\\v^(%([a-zA-Z]:)*[./\\\\]+.{-})$",
                path = 1,
            },
            {
                -- regexp = "^\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.+?)(?:\\s\\s+(.*))?$",
                regex = "\\v^\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.{-1,})%(\\s\\s+(.*))?$",
                lnum = 1,
                col = 2,
                severity = 3,
                message = 4,
                code = 5,
            },
        },
    },
    jest = {
        {
            name = "jest",
            kind = PatternKind.Test,
            regex = [[\v^\s+at .+ \(([^\s]+):(\d+):(\d+)\)$]],
            path = 1,
            lnum = 2,
            col = 3,
        }
    },
    ["python-stacktrace"] = {
        {
            name = "python-stacktrace",
            kind = PatternKind.Stacktrace,
            regex = [[\v^Traceback \(most recent call last\)$]],
            path = 1,
            lnum = 2,
        },
        {
            name = "python-stacktrace",
            kind = PatternKind.Stacktrace,
            regex = [[\v^\s+File \"([^\s]+)", line (\d+), in .+$]],
            path = 1,
            lnum = 2,
        },
        {
            name = "python-stacktrace",
            kind = PatternKind.Stacktrace,
            regex = "", -- TODO: Error message
        },
    },
}

---@return table<string, terminal-diagnostics.Pattern[]>
function patterns.get_all()
    return default_patterns
end

---@generic T
---@param idx integer?
---@param submatches string[]
---@param type_converter (fun(value: unknown): T)?
---@return T?
local function extract(idx, submatches, type_converter)
    if not idx then
        return
    end

    local value = submatches[idx]

    if type(type_converter) == "function" then
        return type_converter(value)
    end

    return value
end

---@param severity string
---@return vim.diagnostic.Severity
local function resolve_severity(severity)
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
function patterns.extract_from_match(match_spec, match)
    local submatches = match.submatches

    -- TODO: Account for cases where only a path is known but no position
    return {
        name = match_spec.name,
        path = submatches[match_spec.path], -- TODO: Resolve path kind
        lnum = extract(match_spec.lnum, submatches, tonumber),
        col = extract(match_spec.col, submatches, tonumber),
        severity = extract(match_spec.severity,submatches, resolve_severity),
        code = submatches[match_spec.code],
        message = submatches[match_spec.message],
    }
end

return patterns
