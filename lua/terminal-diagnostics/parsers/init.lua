local parsers = {}

---@class (exact) terminal-diagnostics.parser.ParseResultContext
---@field lines string[]
---@field range terminal-diagnostics.Range

---@class (exact) terminal-diagnostics.parser.ParseResult
---@field buffer       integer?
---@field range        terminal-diagnostics.Range
---@field command_spec terminal-diagnostics.CommandSpec
---@field context      terminal-diagnostics.parser.ParseResultContext? Extra context lines associated with e.g. a compile error
---@field matches      terminal-diagnostics.Match[]? Optional matches that the parse result might be based on
---@field values       terminal-diagnostics.MatchResult? Optional values as result extraction may be delayed

---@class terminal-diagnostics.ParseContext : terminal-diagnostics.SequentialOutputProcessorOptions

return parsers
