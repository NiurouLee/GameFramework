---@class BaseUtil.ADisposableObjectWithKey<string> : BaseUtil.ADisposableObject
---@field Key string
local m = {}
function m:Dispose() end
---@return string
function m:ToString() end
BaseUtil = {}
BaseUtil.ADisposableObjectWithKey<string> = m
return m