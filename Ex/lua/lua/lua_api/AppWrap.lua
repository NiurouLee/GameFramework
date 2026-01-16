---@class App : object
---@field ShaderABName string
---@field Profiler bool
---@field ShowFps bool
---@field SpeedStatistics bool
---@field StoragePath string
---@field Fps float
---@field TargetFrame int
---@field CMem float
---@field CReservedMem float
---@field Gcmem float
---@field ProcessMem float
---@field TotalMem float
---@field LuaMem float
---@field IsDevelopmentVersion bool
---@field LodLevel LodLevel
---@field CacheFont bool
local m = {}
function m.ClearMemory() end
---@return table
function m.GetCurrenAssets() end
---@return table
function m.GetABs() end
---@return table
function m.GetUnityAbs() end
---@return table
function m.GetResRequests() end
function m.DisposeAll() end
---@param name string
---@param guid int
---@return string
function m.GetTrace(name, guid) end
---@param name string
---@return float
function m.GetAssetTime(name) end
---@param dir string
function m.MakeDir(dir) end
---@return string
function m.GetObjects() end
---@return string
function m.GetBackUpObjects() end
function m.ClearNullObjects() end
---@return table
function m.GetABLoadTimes() end
---@return table
function m.GetABAsyncLoadTimes() end
---@return table
function m.GetAssetLoadTimes() end
---@return table
function m.GetAssetAsyncLoadTimes() end
---@return table
function m.GetGameObjectLoadTimes() end
App = m
return m