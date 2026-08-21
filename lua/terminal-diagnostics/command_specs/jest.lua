local CommandSpec = require("terminal-diagnostics.command_spec")
local HeaderMatcher = require("terminal-diagnostics.matchers.header_matcher")
local HeaderParser = require("terminal-diagnostics.parsers.header_parser")
local range = require("terminal-diagnostics.range")

---@type terminal-diagnostics.MatchSpec
local header_spec = {
    pattern = [[\v\s*(FAIL)\s+(\S+)]], -- TODO: Can we expand header pattern?
    severity = {
        index = 1,
        resolve = function(severity)
            if severity == "FAIL" then
                return "ERROR"
            end

            return "INFO"
        end,
    },
    path = 2,
    path_kind = "relative",
}

---@type terminal-diagnostics.MatchSpec
local error_spec = {
    pattern = [[\v\s+at \S+ \((\S+):(\d+):(\d+)\)]],
    path = 1,
    path_kind = "absolute",
    lnum = 2,
    col = 3,
}

local matcher = HeaderMatcher.new({ header_spec = header_spec, error_spec = error_spec })
local parser = HeaderParser.new()

function parser:is_context_line(line, spec)
    -- Only the header spec has context lines
    if spec.pattern == error_spec.pattern then
        return false
    end

    local _, start_col, _ = unpack(vim.fn.matchstrpos(line, error_spec.pattern))

    return start_col == -1
end

local command_spec =
    CommandSpec.new("jest", CommandSpec.CommandKind.Test, matcher, { parser = parser })

function command_spec:group_parse_results(parse_results)
    ---@type terminal-diagnostics.parser.ParseResult[]
    local grouped_parse_results = {}

    ---@type terminal-diagnostics.parser.ParseResult[]
    local group = {}

    ---@param grouped terminal-diagnostics.parser.ParseResult[]
    ---@return terminal-diagnostics.parser.ParseResult
    local function create_grouped_parse_result(grouped)
        local parse_result = grouped[1]

        local new_message = parse_result.matches[1].text
            .. table.concat(parse_result.context.lines, "\n")
            .. vim.iter(grouped)
            :skip(1)
            :map(function(g)
                return g.matches[1].text
            end)
            :join("\n")

        local ranges = vim.iter(grouped)
            :map(function(g)
                return g.range
            end)
            :totable()

        return {
            buffer = parse_result.buffer,
            range = range.combine(ranges),
            command_spec = parse_result.command_spec,
            context = parse_result.context,
            matches = parse_result.matches,
            values = {
                -- Use the first path from the second match result which is the
                -- top of the stacktrace where the error originated
                paths = { grouped[2].values.paths[1] },
                lnum = grouped[2].values.lnum,
                col = grouped[2].values.col,
                severity = grouped[2].values.severity,
                code = nil,
                message = new_message,
            },
        }
    end

    for idx, parse_result in ipairs(parse_results) do
        table.insert(group, parse_result)

        if
            parse_result.matches[1].spec.pattern == header_spec.pattern
            or idx == #parse_results
        then
            if #group > 1 then
                table.insert(grouped_parse_results, create_grouped_parse_result(group))
                group = {}
            end
        end
    end

    return grouped_parse_results
end

return command_spec
