---@class BaseUtil.CCallEvent : BaseUtil.NetMessage
---@field Encrypt bool
---@field Reliable bool
---@field flag int
local m = {}
---@param ins BaseUtil.NetInStream
function m:FromStream(ins) end
---@param outs BaseUtil.NetOutStream
function m:ToStream(outs) end
BaseUtil = {}
BaseUtil.CCallEvent = m
return m