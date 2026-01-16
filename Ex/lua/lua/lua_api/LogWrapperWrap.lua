---@class LogWrapper
local m = {}
---@param args table
---@return string
function m.Args2Str(args) end
---@overload fun(level:string):bool
---@param eLevel BaseUtil.LogHelper.Level
function m.SetLevel(eLevel) end
---@return string
function m.GetLevel() end
---@param path string
---@return bool
function m.SetPath(path) end
---@return string
function m.GetPath() end
---@param enable bool
function m.SetConsole(enable) end
---@return bool
function m.GetConsole() end
---@param key string
---@param enable bool
---@return bool
function m.SetKey(key, enable) end
---@param key string
---@return bool
function m.GetKey(key) end
function m.ResetKeys() end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogTrace(msg) end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogDebug(msg) end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogInfo(msg) end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogWarning(msg) end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogError(msg) end
---@overload fun(func:System.Func):void
---@overload fun(args:table):void
---@param msg string
function m.LogFatal(msg) end
---@overload fun(cond:bool, func:System.Func):void
---@param cond bool
---@param msg string
function m.LogAssert(cond, msg) end
---@param ex System.Exception
function m.LogException(ex) end
---@overload fun(key:string, func:System.Func):void
---@param key string
---@param msg string
function m.LogKey(key, msg) end
---@overload fun(func:System.Func):void
---@param msg string
function m.LogProf(msg) end
LogWrapper = m
return m