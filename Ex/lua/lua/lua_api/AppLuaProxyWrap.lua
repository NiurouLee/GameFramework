---@class AppLuaProxy : object
local m = {}
---@param func LuaInterface.LuaFunction
function m.OnUpdate(func) end
---@param func LuaInterface.LuaFunction
function m.OnLateUpdate(func) end
---@param func LuaInterface.LuaFunction
function m.OnFixedUpdate(func) end
---@param func LuaInterface.LuaFunction
function m.OnPause(func) end
---@param func LuaInterface.LuaFunction
function m.OnFocus(func) end
---@param func LuaInterface.LuaFunction
function m.OnQuit(func) end
---@param pinchIn LuaInterface.LuaFunction
function m.OnPinchIn(pinchIn) end
---@param pinchOut LuaInterface.LuaFunction
function m.OnPinchOut(pinchOut) end
---@param func LuaInterface.LuaFunction
function m.OnLuaDestroy(func) end
---@param func LuaInterface.LuaFunction
function m.OnMonitor(func) end
AppLuaProxy = m
return m