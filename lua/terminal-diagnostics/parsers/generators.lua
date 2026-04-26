local generators = {}

local matchers = require("terminal-diagnostics.matchers")
local utils = require("terminal-diagnostics.utils")

---@class terminal-diagnostics.parser.GeneratorOptions

--- Generate a parser from a matcher
---@param command_spec terminal-diagnostics.CommandSpec
---@param options terminal-diagnostics.parser.GeneratorOptions
---@return terminal-diagnostics.parser.SimpleMatcherParser
function generators.from_simple_matcher(command_spec, options)
    ---@type terminal-diagnostics.parser.SimpleMatcherParser
    local parser = {
        parse = function(lines, parse_options)
            ---@type terminal-diagnostics.parser.ParseResult[]
            local results = {}
            local start_marker
            local specs = command_spec:matcher().specs()
            local offset = parse_options and parse_options.offset or 0
            local match_extract = false

            if parse_options.context then
                -- TODO: Should this be handled here or in the processors?

                -- Only extract and resolve matches (which may take some time)
                -- if we are adding the results to some kind of list
                if parse_options.context.locationlist or parse_options.context.quickfix or parse_options.context.trouble then
                    match_extract = true
                end
            end

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

                        local parse_result = {
                            source = command_spec:name(),
                            kind = command_spec:kind(),
                            start = { lnum = lnum + offset, col = match.from.col },
                            end_ = { lnum = lnum + offset, col = match.to.col },
                        }

                        if match_extract then
                            parse_result.match = match
                            parse_result.values = matchers.extract_from_match(spec, match)
                        end

                        ---@cast parse_result terminal-diagnostics.parser.ParseResult
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
