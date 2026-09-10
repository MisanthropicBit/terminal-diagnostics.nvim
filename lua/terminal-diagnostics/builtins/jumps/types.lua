---@class terminal-diagnostics.PostJumpContext
---@field command_spec terminal-diagnostics.CommandSpec
---@field match        terminal-diagnostics.Match
---@field buffer       integer
---@field ns           integer
---@field augroup      integer
---@field submatches   terminal-diagnostics.SubgroupParseResult?

---@alias terminal-diagnostics.PostJumpFunc fun(context: terminal-diagnostics.PostJumpContext)
