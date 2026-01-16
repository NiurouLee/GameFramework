---@class ResourceLoader : object
local m = {}
---@param name string
---@param loadType LoadType
---@return string
function m:GetAssetPath(name, loadType) end
---@param name string
---@param loadType LoadType
---@return ResRequest
function m:SyncLoadAsset(name, loadType) end
---@param name string
---@param loadType LoadType
---@return ResRequest
function m:AsyncLoadAsset(name, loadType) end
---@param abname string
function m:CacheAB(abname) end
function m:WarmUpShader() end
---@param abname string
function m:DiposeAB(abname) end
---@param func LuaInterface.LuaFunction
---@param luaTable LuaInterface.LuaTable
function m:OnFinish(func, luaTable) end
---@param num uint
function m:SetSyncLoadNum(num) end
---@param name string
---@return bool
function m:HasResource(name) end
---@param name string
---@return bool
function m:HasLua(name) end
function m:Dispose() end
ResourceLoader = m
return m