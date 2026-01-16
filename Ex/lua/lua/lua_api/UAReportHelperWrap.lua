---@class UAReportHelper : object
---@field EXCEPTION_TYPE_COCOA int
---@field EXCEPTION_TYPE_CS int
---@field EXCEPTION_TYPE_JS int
---@field EXCEPTION_TYPE_LUA int
local m = {}
---@return table
function m.GetUAReportEventInfoConfig() end
---@return table
function m.GetCustomReportEventInfoConfig() end
---@return table
function m.GetParamsDic() end
---@return table
function m.GetParamsList() end
---@param type int
---@param exceptionName string
---@param exceptionMsg string
---@param exceptionStack string
---@param extInfo table
function m.UAReportException(type, exceptionName, exceptionMsg, exceptionStack, extInfo) end
---@param strEventName string
---@param strCustomEventName string
---@param paramsList table
---@param extraJson string
function m.ReportCustomEvent(strEventName, strCustomEventName, paramsList, extraJson) end
---@param uaEventName string
---@param paramsDic table
---@param extraJson string
---@param isRealTime bool
function m.UAReportChannelEvent(uaEventName, paramsDic, extraJson, isRealTime) end
---@param uaEventName string
---@param paramsDic table
---@param extraJson string
---@param isRealTime bool
function m.UAReportEvent(uaEventName, paramsDic, extraJson, isRealTime) end
---@param step uint
---@param stepName string
---@param result bool
---@param errorCode int
---@param paramsJson string
function m.UAReportPayStep(step, stepName, result, errorCode, paramsJson) end
UAReportHelper = m
return m