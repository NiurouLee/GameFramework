---@class BaseUtil.NetMessage : object
---@field CLSID int
---@field Encrypt bool
---@field Reliable bool
local m = {}
---@param ins BaseUtil.NetInStream
function m:FromStream(ins) end
---@param outs BaseUtil.NetOutStream
function m:ToStream(outs) end
---@return string
function m:ToString() end
BaseUtil = {}
BaseUtil.NetMessage = m
return m