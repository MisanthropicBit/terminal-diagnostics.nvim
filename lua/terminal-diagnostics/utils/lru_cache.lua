-- NOTE: Generic classes are not yet supported by luals:
-- https://github.com/LuaLS/lua-language-server/issues/1861

---@class terminal-diagnostics.LruCache
---@field private cache   table<string, unknown>
---@field private default (fun(key: any): any)?
local LruCache = {}

LruCache.__index = LruCache

---@class terminal-diagnostics.LruCacheOptions
---@field max_size integer
---@field default  (fun(key: any): any)?

---@param values  table<string | integer, unknown>?
---@param options terminal-diagnostics.LruCacheOptions
---@return terminal-diagnostics.LruCache
function LruCache.new(values, options)
    vim.validate("values", values, "table")
    vim.validate("options.max_size", options.max_size, "number")
    vim.validate("options.default", options.default, "function", true)

    local lru_cache = setmetatable({
        cache = values or {},
        default = options and options.default,
    }, LruCache)

    return lru_cache
end

---@param key string | integer
---@param value unknown
function LruCache:set(key, value)
    self.cache[key] = value
end

---@param key string | integer
function LruCache:get(key)
    if type(self.default) == "function" then
        self.cache[key] = self.default(key)
    end

    return self.cache[key]
end

---@param key string | integer
function LruCache:remove(key)
    self:set(key, nil)
end

---@return (string | integer)[]?
function LruCache:keys()
    return vim.tbl_keys(self.cache)
end

function LruCache:clear()
    self.cache = {}
end

-- NOTE: __len on tables requires 5.2 or luajit/5.1 compiled to support it
function LruCache:size()
    return vim.tbl_count(self.cache)
end

function LruCache:__pairs(tbl)
    return pairs(tbl)
end

return LruCache
