---@class H3DGCloudLuaHelper : object
---@field MsdkStatus MSDKStatus
local m = {}
---@param eventName string
---@param param LuaInterface.LuaTable
---@param specificChannel string
---@param extraJson string
function m.ReportEvent(eventName, param, specificChannel, extraJson) end
---@param tag string
---@param info string
function m:ReportCrashAssistLog(tag, info) end
---@param key string
---@param value string
function m:SetCrashAssistInfo(key, value) end
---@param crashName string
---@param info string
---@param stack string
---@param extraInfo table
function m:ReportLuaException(crashName, info, stack, extraInfo) end
---@param json string
---@return object
function m.GetMSDKLocalNotification(json) end
---@param url string
---@return string
function m.GetIPAddrByURL(url) end
---@param openID string
function m.SyncOpenID(openID) end
---@param process_name string
function m.PayStart(process_name) end
---@return string
function m.GetOfferId() end
---@param enable bool
function m.SetLogEnable(enable) end
---@param idc string
---@param env string
---@param idc_info string
---@param json string
function m.InitSDK(idc, env, idc_info, json) end
---@param json string
function m.GamePay(json) end
---@param json string
function m.BuyGoods(json) end
---@param json string
function m.BuySubscribe(json) end
---@param req_type string
---@param json string
function m.GetInfo(req_type, json) end
---@param channel string
---@param products LuaInterface.LuaTable
function m.GetLocalPrice(channel, products) end
function m.Reprovide() end
---@param pay_info string
function m.DMMPay(pay_info) end
---@param jsonStr string
---@return string
function m.GetPayToken(jsonStr) end
---@param sceneName string
function m:RecordNewScene(sceneName) end
---@param latencyMs int
function m:ReportNetLatency(latencyMs) end
---@param evt H3DGCloudLuaHelper.FunnelStepEvents
---@param step uint
---@param stepName string
---@param result bool
---@param errorCode int
---@param extraJson string
function m:ReportFunnelStepEvent(evt, step, stepName, result, errorCode, extraJson) end
H3DGCloudLuaHelper = m
return m