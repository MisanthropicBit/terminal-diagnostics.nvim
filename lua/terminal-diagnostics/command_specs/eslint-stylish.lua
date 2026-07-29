local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")
local HeaderParser = require("terminal-diagnostics.parsers.header_parser")

local error_spec_pattern = [[(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]]

-- \v^(\/)?([.A-Za-z0-9-_]+\/)+[.A-Za-z0-9-_]+\.\w+
-- \v^(%([a-zA-Z]:)*[./\\]+.{-})\n

-- \\v^(\\/)?([.A-Za-z0-9-_]+\\/)+[.A-Za-z0-9-_]+\\.\\w+\\s+(\\d+):(\\d+)\\s+(error|warning|info)\\s+(.+)\\s+(.+)?$

-- \\v^((\\/)?([.A-Za-z0-9-_]+\\/)+[.A-Za-z0-9-_]+\\.\\w+)\\n(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$

-- vim.fn.searchpos("\\v^((\\/)?([.A-Za-z0-9-_]+\\/)+[.A-Za-z0-9-_]+\\.\\w+)\\n" .. [[(\d+):(\d+)\s+(error|warning|info)\s+(.+)\s+(.+)?$]], "W")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = "\\v^(%(\\/)?%([.A-Za-z0-9-_]+\\/)+[.A-Za-z0-9-_]+\\.\\w+)\\n\\s+" .. error_spec_pattern,
    path = 1,
    path_kind = "absolute",
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    pattern = [[\v^\s+]] .. error_spec_pattern,
    lnum = 1,
    col = 2,
    severity = 3,
    message = 4,
    code = 5,
}

local matcher = HeaderMatcher.new({
    header_spec = header_spec,
    error_spec = error_spec,
})

return CommandSpec.new("eslint-stylish", CommandSpec.CommandKind.Lint, matcher, {
    parser = HeaderParser.new()
})
