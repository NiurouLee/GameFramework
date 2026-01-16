---@class NetCallerLua : BaseUtil.NetCaller
---@field Lua LuaInterface.LuaTable
---@field ConnectDoneCallback System.Action
---@field ConnectFailedCallback System.Action
---@field ConnectClosedCallback System.Action
---@field ReceiveDoneCallback System.Action
---@field CallBeginCallback System.Action
---@field CallEndCallback System.Action
---@field CallTimelongCallback System.Action
---@field CallTimeoutCallback System.Action
local m = {}
---@param table LuaInterface.LuaTable
function m:Bind(table) end
---@param table LuaInterface.LuaTable
function m.BindStaticFunc(table) end
---@param clsid int
---@param type LuaEventType
---@param encrypt bool
---@param reliable bool
---@param name string
function m.RegisterEvents(clsid, type, encrypt, reliable, name) end
---@param reason string
function m:Base_Reset(reason) end
function m:Base_Init() end
---@param msg LuaInterface.LuaTable
function m:Push(msg) end
---@param msg LuaInterface.LuaTable
---@param id int
---@param sync bool
---@param timeout uint
function m:Call(msg, id, sync, timeout) end
function m:Base_HandleConnectDone() end
---@param reason string
function m:Base_HandleConnectFailed(reason) end
---@param reason string
function m:Base_HandleConnectClosed(reason) end
---@param msg BaseUtil.NetMessage
function m:Base_HandleReceiveDone(msg) end
---@param msg BaseUtil.NetMessage
function m:Base_HandleCallBegin(msg) end
---@param msg BaseUtil.NetMessage
function m:Base_HandleCallEnd(msg) end
---@param msg BaseUtil.NetMessage
function m:Base_HandleCallTimelong(msg) end
function m:Base_HandleCallTimeout() end
NetCallerLua = m
return m