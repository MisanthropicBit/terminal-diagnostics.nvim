local CommandSpec = require("terminal-diagnostics.command_spec")
local SimpleMatcher = require("terminal-diagnostics.matchers.simple_matcher")
local SimpleParser = require("terminal-diagnostics.parsers.simple_parser")

-- require("terminal-diagnostics").patterns.find(361, { pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=], path_kind = "relative", path = 1, lnum = 2, col = 3, severity = 4, code = 5, message = 6 }, 1)

---@type terminal-diagnostics.MatchSpec
local match_spec = {
    pattern = [=[\v^([^[:space:]].*)[\(:](\d+)[,:](\d+)%(\):\s+|\s+-\s+)(error|warning|info)\s+TS(\d+)\s*:\s*(.*)$]=],
    path_kind = "relative",
    path = 1,
    lnum = 2,
    col = 3,
    severity = 4,
    code = 5,
    message = 6,
}

local matcher = SimpleMatcher.new({ specs = { match_spec } })
local parser = SimpleParser.new()

parser:extend({
    ---@param self terminal-diagnostics.parser.SimpleMatcherParser
    ---@param line string
    ---@return boolean
    is_context_line = function(self, line)
        if line:match("%s+~+") then
            ---@diagnostic disable-next-line: inject-field
            self._underline_state = 1

            return true
        else
            if self._underline_state == 1 then
                ---@diagnostic disable-next-line: inject-field
                self._underline_state = self._underline_state + 1

                return true
            elseif self._underline_state == 2 then
                ---@diagnostic disable-next-line: inject-field
                self._underline_state = 0

                return false
            end

            return true
        end
    end,
})

return CommandSpec.new(
    "tsc",
    CommandSpec.CommandKind.Build,
    matcher,
    { parser = parser }
)
