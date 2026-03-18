local generators = {}

local matchers = require("terminal-diagnostics.matchers")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.parser.GeneratorOptions

--- Generate a parser from a matcher
---@param command_spec terminal-diagnostics.CommandSpec
---@param options terminal-diagnostics.parser.GeneratorOptions
---@return terminal-diagnostics.parser.Parser
function generators.from_simple_matcher(command_spec, options)
    ---@type terminal-diagnostics.parser.Parser
    local parser = {
        parse = function(lines, parse_options)
            ---@type terminal-diagnostics.parser.ParseResult[]
            local results = {}
            local start_marker
            local specs = command_spec:matcher().specs()
            local offset = parse_options and parse_options.offset or 0

            for lnum, line in ipairs(lines) do
                for _, spec in ipairs(specs) do
                    -- Skip specs that contain no information
                    if not matchers.spec_has_info(spec) then
                        goto continue
                    end

                    local match = utils.patterns.find_in_line(line, spec)

                    if match then
                        -- TODO: Support for:
                        -- 1. Additional error output between error lines
                        -- 2. Additional error output after and between error lines
                        -- 3. No additional error output

                        if start_marker then
                            results[#results].context = vim.list_slice(lines, start_marker, lnum - 1)
                        end

                        local parse_result = matchers.extract_from_match(spec, match)
                        ---@cast parse_result terminal-diagnostics.parser.ParseResult

                        parse_result.source = command_spec:name()
                        parse_result.kind = command_spec:kind()
                        parse_result.start = { lnum = lnum + offset, col = match.from.col }
                        parse_result.end_ = { lnum = lnum + offset, col = match.to.col }

                        table.insert(results, parse_result)

                        -- Start the match for intermediary error output after the actual error line
                        start_marker = lnum + 1
                    end

                    :: continue ::
                end
            end

            -- Parse any remaining lines that are not delimited by an end pattern
            if start_marker < #lines then
                local context = vim.list_slice(lines, start_marker, #lines)
                local is_empty = vim.iter(context):all(function(line)
                    return vim.fn.trim(line) == ""
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
