-- NOTE: Generic classes are not yet supported by luals:
-- https://github.com/LuaLS/lua-language-server/issues/1861

---@class terminal-diagnostics.Cache
---@field private cache   table<string, unknown>
---@field private default (fun(key: any): any)?
local Cache = {}

Cache.__index = Cache

---@class terminal-diagnostics.CacheOptions
---@field default (fun(key: any): any)?

---@param values  table<string | integer, unknown>?
---@param options terminal-diagnostics.CacheOptions?
---@return terminal-diagnostics.Cache
function Cache.new(values, options)
    vim.validate("values", values, "table")
    vim.validate("options.default", options and options.default, "function", true)

    local cache = setmetatable({
        cache = values or {},
        default = options and options.default,
    }, Cache)

    return cache
end

---@param key string | integer
---@param value unknown
function Cache:set(key, value)
    self.cache[key] = value
end

---@param key string | integer
function Cache:get(key)
    if type(self.default) == "function" then
        self.cache[key] = self.default(key)
    end

    return self.cache[key]
end

---@param key string | integer
function Cache:remove(key)
    self:set(key, nil)
end

---@return (string | integer)[]?
function Cache:keys()
    return vim.tbl_keys(self.cache)
end

function Cache:clear()
    self.cache = {}
end

-- NOTE: __len on tables requires 5.2 or luajit/5.1 compiled to support it
function Cache:size()
    return vim.tbl_count(self.cache)
end

function Cache:__pairs(tbl)
    return pairs(tbl)
end

return Cache
