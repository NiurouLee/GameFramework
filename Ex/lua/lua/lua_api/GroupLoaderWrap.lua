---@class GroupLoader : object
---@field disposed bool
local m = {}
---@param func LuaInterface.LuaFunction
function m:OnFinish(func) end
function m:SetLast() end
function m:CheckFinish() end
---@return double
function m:GetProgress() end
---@return long
function m:GetSize() end
---@return table
function m:GetResources() end
---@param file string
---@param loadType LoadType
---@return ResRequest
function m:LoadAsync(file, loadType) end
---@param file string
---@param loadType LoadType
---@return ResRequest
function m:LoadSync(file, loadType) end
---@param pattern string
---@param loadType LoadType
function m:LoadGroup(pattern, loadType) end
---@param request ResRequest
function m:UnLoad(request) end
function m:BeginRecord() end
function m:EndRecord() end
function m:Dispose() end
GroupLoader = m
return m