---@class UnityEngine.Logger : object
---@field logHandler UnityEngine.ILogHandler
---@field logEnabled bool
---@field filterLogType UnityEngine.LogType
local m = {}
---@param logType UnityEngine.LogType
---@return bool
function m:IsLogTypeAllowed(logType) end
---@overload fun(logType:UnityEngine.LogType, message:object, context:UnityEngine.Object):void
---@overload fun(logType:UnityEngine.LogType, tag:string, message:object):void
---@overload fun(logType:UnityEngine.LogType, tag:string, message:object, context:UnityEngine.Object):void
---@overload fun(message:object):void
---@overload fun(tag:string, message:object):void
---@overload fun(tag:string, message:object, context:UnityEngine.Object):void
---@param logType UnityEngine.LogType
---@param message object
function m:Log(logType, message) end
---@overload fun(tag:string, message:object, context:UnityEngine.Object):void
---@param tag string
---@param message object
function m:LogWarning(tag, message) end
---@overload fun(tag:string, message:object, context:UnityEngine.Object):void
---@param tag string
---@param message object
function m:LogError(tag, message) end
---@overload fun(logType:UnityEngine.LogType, context:UnityEngine.Object, format:string, args:table):void
---@param logType UnityEngine.LogType
---@param format string
---@param args table
function m:LogFormat(logType, format, args) end
---@overload fun(exception:System.Exception, context:UnityEngine.Object):void
---@param exception System.Exception
function m:LogException(exception) end
UnityEngine = {}
UnityEngine.Logger = m
return m