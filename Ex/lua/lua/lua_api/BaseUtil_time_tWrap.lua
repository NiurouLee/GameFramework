---@class BaseUtil.time_t : object
---@field dTime System.DateTime
local m = {}
---@return long
function m:AsLong() end
---@param dtime System.DateTime
function m:SetTime(dtime) end
---@overload fun(time:long):void
---@param time BaseUtil.time_t
function m:Set(time) end
---@param large BaseUtil.time_t
---@param little BaseUtil.time_t
---@return long
function m.Diff(large, little) end
BaseUtil = {}
BaseUtil.time_t = m
return m