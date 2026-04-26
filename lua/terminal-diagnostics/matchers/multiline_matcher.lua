local Matcher = require("terminal-diagnostics.matchers.matcher")
local utils = require("terminal-diagnostics.utils")
local matchers = require("terminal-diagnostics.matchers")
local matcher_utils = require("terminal-diagnostics.matchers.utils")

---@class terminal-diagnostics.MultilineMatcherOptions
---@field specs terminal-diagnostics.MatchSpec[]

--- A matcher that matches errors where information is split across multiple
--- lines and aggregates results on extraction
---@class terminal-diagnostics.MultilineMatcher : terminal-diagnostics.Matcher
---@field private _specs terminal-diagnostics.MatchSpec[]
local MultilineMatcher = setmetatable({}, Matcher)

MultilineMatcher.__index = MultilineMatcher

---@param options terminal-diagnostics.MultilineMatcherOptions
---@return terminal-diagnostics.MultilineMatcher
function MultilineMatcher.new(options)
    return setmetatable({ specs = options.specs }, MultilineMatcher)
end

---@return terminal-diagnostics.MatchSpec[]
function MultilineMatcher:specs()
    return self._specs
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.MatchResult2[]
function MultilineMatcher:match(options)
    local buffer = options.buffer
    local count = options.count or 1
    local results = {}

    if self.last_match_pos then
        match = utils.patterns.find_at_cursor(buffer, self.error_spec.pattern)

        if match then
            self.last_match_pos = nil
            table.insert(results, { spec = self.error_spec, match = match })
        end
    else
        local match, spec_idx

        -- Figure out if the cursor is on a spec
        for idx, spec in ipairs(self:specs()) do
            local match = utils.patterns.find_at_cursor(buffer, spec)

            if match then
                spec_idx = idx
                break
            end
        end

        if match then
            -- Cursor was already on a match, find the rest of the specs
            for idx, spec in ipairs(self:specs()) do
                if idx ~= spec_idx then
                    local dir = idx < spec_idx and -1 or 1
                    local _match = utils.patterns.find(buffer, spec, dir)

                    if _match then
                        table.insert(results, { spec = spec, match = _match })
                    end
                end
            end

            if #results ~= #self:specs() then
                -- TODO: Support optional specs?

                -- We did not find all the required specs
                results = {}
            end
        end

        local on_header =
            utils.patterns.find_at_cursor(buffer, self.header_spec.pattern)

        if on_header then
            local include_header = matcher_utils.spec_has_fileinfo(self.header_spec)

            if include_header then
                -- If on a header that should be included (has info), just
                -- return that
                match, spec = on_header, self.header_spec

                if match then
                    table.insert(results, { spec = spec, match = match })
                end
            else
                match, spec =
                    utils.patterns.find(buffer, self.error_spec, count),
                    self.error_spec

                if match then
                    table.insert(results, {
                        spec = self.error_spec,
                        match = utils.patterns.find(buffer, self.error_spec, count),
                    })
                end
            end

            if match then
                return { spec, match }
            end
        else
            local error_match = utils.patterns.find(buffer, self.error_spec, count)

            if error_match then
                local include_header =
                    matcher_utils.spec_has_fileinfo(self.header_spec)

                if include_header then
                    -- If including the header, find it and add it
                    local header_match =
                        utils.patterns.find(buffer, self.error_spec, count)

                    if header_match then
                        table.insert(
                            results,
                            { spec = self.header_spec, match = header_match }
                        )
                    end
                end

                table.insert(
                    results,
                    { spec = self.error_spec, match = error_match }
                )
            end
        end
    end

    return {}
end

---@param options terminal-diagnostics.MatchOptions
---@return terminal-diagnostics.Match?
function MultilineMatcher:find_match_start(options)
    local buffer = options.buffer
    local count = options.count or 1
    local include_header = matcher_utils.spec_has_info(self.header_spec)
    local error_line_pos = utils.patterns.find(buffer, self.error_spec, count)

    if include_header then
        local header_pos = utils.patterns.find(buffer, self.header_spec, count)

        if header_pos and error_line_pos then
            if header_pos.from.lnum < error_line_pos.from.lnum then
                self.last_match_pos = header_pos
            else
                self.last_match_pos = error_line_pos
            end
        elseif error_line_pos then
            self.last_match_pos = error_line_pos
        end
    else
        if error_line_pos then
            self.last_match_pos = error_line_pos
        else
            self.last_match_pos = nil
        end
    end

    return self.last_match_pos
end

---@param options terminal-diagnostics.MatchAtCursorOptions
function MultilineMatcher:match_at_cursor(options)
    for _, spec in ipairs(self:specs()) do
        if matcher_utils.spec_has_info(spec) then
            local match = utils.patterns.find_at_cursor(options.buffer, spec)

            if match then
                return spec, match
            end
        end
    end
end

function MultilineMatcher:extract_values(results)
    -- TODO: Either find header in buffer now or do it in match. If latter
    -- solution, then we need to expand MatchSpec to contain more information
    ---@diagnostic disable-next-line: missing-fields
    local match_data = {} ---@type terminal-diagnostics.MatchResult

    for _, result in ipairs(results) do
        local data = matchers.extract_from_match(result.spec, result.match)

        vim.tbl_extend("force", match_data, data)
    end

    return match_data
end

return MultilineMatcher
