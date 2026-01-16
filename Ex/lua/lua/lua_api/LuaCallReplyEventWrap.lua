---@class LuaCallReplyEvent : BaseUtil.CCallReplyEvent
---@field CLSID int
---@field Encrypt bool
---@field Reliable bool
---@field flag int
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
LuaCallReplyEvent = m
return m