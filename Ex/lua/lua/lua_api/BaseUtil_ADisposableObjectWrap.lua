---@class BaseUtil.ADisposableObject : object
---@field InstanceId long
---@field IsDisposed bool
local m = {}
function m:Dispose() end
BaseUtil = {}
BaseUtil.ADisposableObject = m
return m