---@class UnityEngine.Debug : object
---@field unityLogger UnityEngine.ILogger
---@field developerConsoleVisible bool
---@field isDebugBuild bool
local m = {}
---@overload fun(start:UnityEngine.Vector3, end:UnityEngine.Vector3, color:UnityEngine.Color):void
---@overload fun(start:UnityEngine.Vector3, end:UnityEngine.Vector3):void
---@overload fun(start:UnityEngine.Vector3, end:UnityEngine.Vector3, color:UnityEngine.Color, duration:float, depthTest:bool):void
---@param start UnityEngine.Vector3
---@param end UnityEngine.Vector3
---@param color UnityEngine.Color
---@param duration float
function m.DrawLine(start, end, color, duration) end
---@overload fun(start:UnityEngine.Vector3, dir:UnityEngine.Vector3, color:UnityEngine.Color):void
---@overload fun(start:UnityEngine.Vector3, dir:UnityEngine.Vector3):void
---@overload fun(start:UnityEngine.Vector3, dir:UnityEngine.Vector3, color:UnityEngine.Color, duration:float, depthTest:bool):void
---@param start UnityEngine.Vector3
---@param dir UnityEngine.Vector3
---@param color UnityEngine.Color
---@param duration float
function m.DrawRay(start, dir, color, duration) end
function m.Break() end
function m.DebugBreak() end
---@overload fun(message:object, context:UnityEngine.Object):void
---@param message object
function m.Log(message) end
---@overload fun(context:UnityEngine.Object, format:string, args:table):void
---@param format string
---@param args table
function m.LogFormat(format, args) end
---@overload fun(message:object, context:UnityEngine.Object):void
---@param message object
function m.LogError(message) end
---@overload fun(context:UnityEngine.Object, format:string, args:table):void
---@param format string
---@param args table
function m.LogErrorFormat(format, args) end
function m.ClearDeveloperConsole() end
---@overload fun(exception:System.Exception, context:UnityEngine.Object):void
---@param exception System.Exception
function m.LogException(exception) end
---@overload fun(message:object, context:UnityEngine.Object):void
---@param message object
function m.LogWarning(message) end
---@overload fun(context:UnityEngine.Object, format:string, args:table):void
---@param format string
---@param args table
function m.LogWarningFormat(format, args) end
---@overload fun(condition:bool, context:UnityEngine.Object):void
---@overload fun(condition:bool, message:object):void
---@overload fun(condition:bool, message:string):void
---@overload fun(condition:bool, message:object, context:UnityEngine.Object):void
---@overload fun(condition:bool, message:string, context:UnityEngine.Object):void
---@param condition bool
function m.Assert(condition) end
---@overload fun(condition:bool, context:UnityEngine.Object, format:string, args:table):void
---@param condition bool
---@param format string
---@param args table
function m.AssertFormat(condition, format, args) end
---@overload fun(message:object, context:UnityEngine.Object):void
---@param message object
function m.LogAssertion(message) end
---@overload fun(context:UnityEngine.Object, format:string, args:table):void
---@param format string
---@param args table
function m.LogAssertionFormat(format, args) end
UnityEngine = {}
UnityEngine.Debug = m
return m