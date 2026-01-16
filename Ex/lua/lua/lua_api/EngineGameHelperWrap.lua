---@class EngineGameHelper : object
---@field StoragePath string
---@field GetUserIDFA string
---@field PerformanceLevel int
---@field GCloudGameID string
local m = {}
---@return string
function m.GetActiveURL() end
function m.ClearActiveURL() end
---@param buffer table
---@return string
function m.GetUTF8String(buffer) end
function m.QuitApp() end
---@param touchIndex int
---@return UnityEngine.Vector2
function m.GetMousePosition(touchIndex) end
---@param x float
---@param y float
---@return bool
function m.IsTouchOverUI(x, y) end
---@param uiName string
---@param x float
---@param y float
---@return bool
function m.IsTouchUINamed(uiName, x, y) end
---@param str string
---@param startIdx int
---@param len int
---@return string
function m.SubString(str, startIdx, len) end
---@return string
function m.CurrentAppVersion() end
---@return string
function m.CurrentResVersion() end
---@return System.Version
function m.GetCurrentAppVersion() end
---@return System.Version
function m.GetCurrentResVersion() end
---@return bool
function m.EnableAppleVerifyBulletin() end
---@return bool
function m.IsEnableHotUpdate() end
---@return BulletinInfo
function m.GetVerifyBulletinInfo() end
---@return table
function m.GetBulletinConfig() end
---@return ChannelConfigInfo
function m.ChannelConfig() end
---@return string
function m.ChannelSign() end
---@param str string
---@return string
function m.UrlEncode(str) end
---@param str string
---@return string
function m.Urlcode(str) end
---@return int
function m.SAIchannelId() end
---@param longName string
---@return string
function m.GetName(longName) end
---@return string
function m.GetTssReportDataString() end
---@param filePath string
---@return bool
function m.IsInApp(filePath) end
---@return string
function m.GetLocalIp() end
---@return int
function m.GetCurrentProcessId() end
---@param type MediaType
---@param srcAbsPath string
---@param delSrcFile bool
---@param handler FinishSavedToMediaHandler
---@param destRelativePath string
---@return bool
function m.SaveToMediaFile(type, srcAbsPath, delSrcFile, handler, destRelativePath) end
---@param mediaAbsPath string
---@return bool
function m.RefreshMediaToShow(mediaAbsPath) end
---@return bool
function m.IsDevelopmentBuild() end
---@return string
function m.GetAndroidID() end
EngineGameHelper = m
return m