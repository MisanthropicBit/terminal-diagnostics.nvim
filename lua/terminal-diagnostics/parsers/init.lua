local parsers = {}

---@class (exact) terminal-diagnostics.parser.ParseResult: terminal-diagnostics.MatchResult
---@field source  string
---@field kind    terminal-diagnostics.CommandKind
---@field start   terminal-diagnostics.Position
---@field end_    terminal-diagnostics.Position
---@field context string[] Extra context lines associated with e.g. a compile error

---@class terminal-diagnostics.parser.Parser
---@field parse fun(lines: string[]): terminal-diagnostics.parser.ParseResult[]

return parsers
