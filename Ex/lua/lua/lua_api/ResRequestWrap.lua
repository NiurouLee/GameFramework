---@class ResRequest : object
---@field Obj object
---@field keepWaiting bool
---@field m_Ready bool
---@field m_Name string
---@field m_LoadType LoadType
---@field m_AssetInfo AssetInfo
---@field m_ABInfo ABInfo
---@field m_RemoteInfo RemoteInfo
local m = {}
---@return bool
function m:Ready() end
---@param name string
---@param loadType LoadType
---@param assetInfo AssetInfo
function m:SetAsset(name, loadType, assetInfo) end
---@param name string
---@param loadType LoadType
---@param abinfo ABInfo
function m:SetABInfo(name, loadType, abinfo) end
---@return bool
function m:CheckNotNull() end
---@return string
function m:GetPath() end
---@return long
function m:GetSize() end
---@param name string
---@param guid int
---@return string
function m.GetTrace(name, guid) end
---@param name string
---@return float
function m.GetTime(name) end
function m:Dispose() end
ResRequest = m
return m