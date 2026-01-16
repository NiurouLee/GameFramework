---@class GCloud.AnoSDK.AnoSDK
local m = {}
---@param gameId int
function m.Init(gameId) end
---@param entryId int
---@param openId string
function m.SetUserInfo(entryId, openId) end
function m.OnPause() end
function m.OnResume() end
---@return table
function m.GetReportData() end
---@param data table
function m.OnRecvData(data) end
---@return table
function m.GetReportData2() end
---@return table
function m.GetReportData3() end
---@param name string
---@param buf table
---@param buf_len uint
---@param crc uint
function m.OnRecvSignature(name, buf, buf_len, crc) end
---@param request int
---@param cmd string
---@return string
function m.Ioctl(request, cmd) end
GCloud = {}
GCloud.AnoSDK = {}
GCloud.AnoSDK.AnoSDK = m
return m