local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")
local SimpleParser = require("terminal-diagnostics.parsers.simple_parser")

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [=[\v\zs^([^[:space:]].*):(\d+):(\d+): (\w+): (\[GHC-\d+\])(\n\s+(.+))+\ze\\n\s+\|]=],
    subpatterns = {
        [=[\v^([^[:space:]].*):(\d+):(\d+): (\w+): (\[GHC-\d+\])]=],
        { [=[(\s+(.+))+\n\s+\|]=], multiple = true },
    },
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })
local parser = SimpleParser.new({ has_context = true })

function parser:is_context_line(line)
    return line:match("^%s*|") or line:match("^%s*%d+ |")
end

return CommandSpec.new(
    "haskell",
    CommandSpec.CommandKind.Build,
    matcher,
    { parser = parser }
)
