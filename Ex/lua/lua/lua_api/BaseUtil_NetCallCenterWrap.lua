---@class BaseUtil.NetCallCenter : BaseUtil.ADisposableObject
local m = {}
---@return BaseUtil.NetCallCenter
function m.GetInstance() end
function m:Dispose() end
---@param reason string
function m:Reset(reason) end
function m:Init() end
---@param curTick BaseUtil.tick_t
function m:Update(curTick) end
---@param key string
---@return LuaInterface.LuaTable
function m:GetCallerLua(key) end
---@param table LuaInterface.LuaTable
---@param key string
function m:AddCallerLua(table, key) end
---@param key string
---@param reason string
---@return bool
function m:DelCaller(key, reason) end
---@param reason string
function m:ResetCallers(reason) end
function m:InitCallers() end
---@param reason string
function m:ResetCallersCall(reason) end
BaseUtil = {}
BaseUtil.NetCallCenter = m
return m