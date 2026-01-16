---@class HotUpdateLuaProxy : object
local m = {}
---@param func LuaInterface.LuaFunction
function m.AddListener(func) end
---@return HotUpdate.HotUpdateVersionCheckResult
function m.GetVersionCheckRes() end
---@return float
function m.GetProgress() end
---@return string
function m.GetTotalSize() end
---@return string
function m.GetDownloadedSize() end
---@return string
function m.GetSpeed() end
function m.RetryDownload() end
---@return bool
function m.IsHotUpdateFinish() end
HotUpdateLuaProxy = m
return m