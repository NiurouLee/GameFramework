---@class LuaSvrPushEvent : BaseUtil.CSvrPushEvent
---@field CLSID int
---@field Encrypt bool
---@field Reliable bool
local m = {}
---@param lua LuaInterface.LuaTable
---@return bool
function m:Encode(lua) end
---@param lua LuaInterface.LuaTable
---@return bool
function m:Decode(lua) end
---@param ins BaseUtil.NetInStream
function m:FromStream(ins) end
---@param outs BaseUtil.NetOutStream
function m:ToStream(outs) end
---@return string
function m:ToString() end
LuaSvrPushEvent = m
return m