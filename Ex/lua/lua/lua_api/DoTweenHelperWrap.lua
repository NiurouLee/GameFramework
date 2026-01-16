---@class DoTweenHelper : object
local m = {}
---@param oldValue int
---@param newValue int
---@param duration float
---@param updateCallback System.Action
function m.DoUpdateInt(oldValue, newValue, duration, updateCallback) end
---@param oldValue float
---@param newValue float
---@param duration float
---@param updateCallback System.Action
function m.DoUpdateFloat(oldValue, newValue, duration, updateCallback) end
DoTweenHelper = m
return m