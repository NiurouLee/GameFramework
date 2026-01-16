---@class LocalDB : object
local m = {}
---@param key string
---@param default_value int
---@return int
function m.GetInt(key, default_value) end
---@param key string
---@param default_value string
---@return string
function m.GetString(key, default_value) end
---@param key string
---@param default_value float
---@return float
function m.GetFloat(key, default_value) end
---@param key string
---@param val int
function m.SetInt(key, val) end
---@param key string
---@param val string
function m.SetString(key, val) end
---@param key string
---@param val float
function m.SetFloat(key, val) end
---@param key string
---@return bool
function m.HasKey(key) end
function m.ClearDB() end
---@param key string
function m.Delete(key) end
LocalDB = m
return m