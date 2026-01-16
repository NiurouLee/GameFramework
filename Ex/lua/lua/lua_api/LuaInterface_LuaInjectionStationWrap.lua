---@class LuaInterface.LuaInjectionStation : object
---@field NOT_INJECTION_FLAG byte
---@field INVALID_INJECTION_FLAG byte
local m = {}
---@param index int
---@param injectFlag byte
---@param func LuaInterface.LuaFunction
function m.CacheInjectFunction(index, injectFlag, func) end
function m.Clear() end
LuaInterface = {}
LuaInterface.LuaInjectionStation = m
return m