-- TODO: Make a buffer cache for parsed results that can be used
-- to quickly open, select, or jump to errors

-- TODO: Rename to stable_buffer_cache
local buffer_cache = {}

local Cache = require("terminal-diagnostics.utils.cache")
local range = require("terminal-diagnostics.range")
local utils = require("terminal-diagnostics.api.utils")

---@class terminal-diagnostics.BufferCacheEntry
---@field parse_results terminal-diagnostics.SortedList?
---@field diagnostics   vim.Diagnostic.Set[]?

---@type terminal-diagnostics.Cache
local _buffer_cache = Cache.new(nil, {
    default = function(_)
        return {
            parse_results = nil,
            diagnostics = nil,
        }
    end
})

---@param buffer integer
---@param parsed_results terminal-diagnostics.parser.ParseResult[]
function buffer_cache.set(buffer, parsed_results)
    local cache = _buffer_cache[buffer]

    if not cache then
        return
    end

    cache:set(buffer, parsed_results)
end

---@param buffer integer
---@return terminal-diagnostics.BufferCacheEntry?
function buffer_cache.get(buffer)
    return _buffer_cache:get(buffer)
end

---@param lnum integer
---@param buffer integer
---@return terminal-diagnostics.parser.ParseResult?
function buffer_cache.find(lnum, buffer)
    local parsed_results = _buffer_cache:get(buffer)

    if not parsed_results then
        return
    end

    return utils.binary_search(parsed_results, function(item)
        if range.below(item.range, lnum) then
            return 1
        elseif range.above(item.range, lnum) then
            return -1
        end

        return range.contains(item.range, lnum) and 0 or nil
    end)
end

return buffer_cache
