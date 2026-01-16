---@class HotUpdate.ActivityLuaProxy
local m = {}
---@param activityId ushort
---@return bool
function m.HasDownloadList(activityId) end
---@param luaFunction LuaInterface.LuaFunction
function m.AddListener(luaFunction) end
---@return bool
function m.IsDownloaderBusy() end
---@return uint
function m.CurrProcessingActivityID() end
---@param activityId ushort
function m.StartDownload(activityId) end
---@return float
function m.GetProgress() end
---@param activityId ushort
---@return string
function m.GetTotalSize(activityId) end
---@return string
function m.GetDownloadedSize() end
---@return string
function m.GetSpeed() end
function m.SaveManifestImmediately() end
function m.Dispose() end
HotUpdate = {}
HotUpdate.ActivityLuaProxy = m
return m