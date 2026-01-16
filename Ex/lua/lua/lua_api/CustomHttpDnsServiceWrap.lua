---@class CustomHttpDnsService : object
local m = {}
---@param domain string
---@param func LuaInterface.LuaFunction
function m.GetAddrByName(domain, func) end
function m.Update() end
---@param domain string
---@param addr_type System.Net.Sockets.AddressFamily
---@return string
function m.AgainAnalysis(domain, addr_type) end
---@param address string
---@return bool
function m.Ip4or6IsValid(address) end
---@param address string
---@return bool
function m.IpIsValid(address) end
CustomHttpDnsService = m
return m