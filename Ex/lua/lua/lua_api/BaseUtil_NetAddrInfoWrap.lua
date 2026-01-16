---@class BaseUtil.NetAddrInfo : object
---@field IsEmpty bool
---@field host string
---@field port ushort
---@field protocol BaseUtil.NetworkProtocol
local m = {}
---@param host string
---@param port ushort
---@return BaseUtil.NetAddrInfo
function m.New2(host, port) end
---@param host string
---@param port ushort
---@param protocol BaseUtil.NetworkProtocol
---@return BaseUtil.NetAddrInfo
function m.New3(host, port, protocol) end
---@overload fun(host:string, port:ushort, protocol:BaseUtil.NetworkProtocol):void
---@param addr BaseUtil.NetAddrInfo
function m:Reset(addr) end
---@return int
function m:GetHashCode() end
---@param obj object
---@return bool
function m:Equals(obj) end
---@return string
function m:ToString() end
BaseUtil = {}
BaseUtil.NetAddrInfo = m
return m