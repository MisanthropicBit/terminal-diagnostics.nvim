local generators = {}

local matchers = require("terminal-diagnostics.matchers")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.parser.GeneratorOptions

--- Generate a parser from a matcher
---@param matcher terminal-diagnostics.Matcher
---@param options terminal-diagnostics.parser.GeneratorOptions
---@return terminal-diagnostics.parser.Parser
function generators.from_simple_matcher(matcher, options)
    ---@type terminal-diagnostics.parser.Parser
    local parser = {
        parse = function(lines)
            ---@type terminal-diagnostics.parser.ParseResult[]
            local results = {}
            local start_marker
            local spec = matcher.spec()

            for lnum, line in ipairs(lines) do
                local match = utils.patterns.find_in_line(line, spec)

                if match then
                    -- TODO: Support for:
                    -- 1. Additional error output between error lines
                    -- 2. Additional error output after and between error lines
                    -- 3. No additional error output

                    if start_marker then
                        results[#results].context = vim.list_slice(lines, start_marker, lnum - 1)
                    else
                        table.insert(results, matchers.extract_from_match(spec, match))

                        -- Start the match for intermediary error output after the actual error line
                        start_marker = lnum + 1
                    end
                end
            end

            if start_marker < #lines then
                local context = vim.list_slice(lines, start_marker, #lines)
                local is_empty = vim.iter(context):map(vim.fn.trim):all(function(line)
                    return line == ""
                end)

                if not is_empty then
                    results[#results].context = context
                end
            end

            return results
        end
    }

    return parser
end

return generators
