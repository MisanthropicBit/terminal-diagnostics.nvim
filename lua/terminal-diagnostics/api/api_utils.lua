local api_utils = {}

---@param api_result terminal-diagnostics.ApiResult
---@return terminal-diagnostics.parser.ParseResult?
function api_utils.get_single_parse_result_with_context(api_result)
    local parse_results = api_result.command_spec:parser():parse_buffer(0, {
        offset = api_result.results[1].match.from.lnum,
        count = 1,
    })

    if #parse_results == 1 and parse_results[1].context then
        return parse_results[1]
    end
end

return api_utils
