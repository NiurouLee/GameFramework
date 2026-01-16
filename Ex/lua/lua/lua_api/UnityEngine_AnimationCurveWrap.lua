---@class UnityEngine.AnimationCurve : object
---@field keys table
---@field Item UnityEngine.Keyframe
---@field length int
---@field preWrapMode UnityEngine.WrapMode
---@field postWrapMode UnityEngine.WrapMode
local m = {}
---@param time float
---@return float
function m:Evaluate(time) end
---@overload fun(key:UnityEngine.Keyframe):int
---@param time float
---@param value float
---@return int
function m:AddKey(time, value) end
---@param index int
---@param key UnityEngine.Keyframe
---@return int
function m:MoveKey(index, key) end
---@param index int
function m:RemoveKey(index) end
---@param index int
---@param weight float
function m:SmoothTangents(index, weight) end
---@param timeStart float
---@param timeEnd float
---@param value float
---@return UnityEngine.AnimationCurve
function m.Constant(timeStart, timeEnd, value) end
---@param timeStart float
---@param valueStart float
---@param timeEnd float
---@param valueEnd float
---@return UnityEngine.AnimationCurve
function m.Linear(timeStart, valueStart, timeEnd, valueEnd) end
---@param timeStart float
---@param valueStart float
---@param timeEnd float
---@param valueEnd float
---@return UnityEngine.AnimationCurve
function m.EaseInOut(timeStart, valueStart, timeEnd, valueEnd) end
---@overload fun(other:UnityEngine.AnimationCurve):bool
---@param o object
---@return bool
function m:Equals(o) end
---@return int
function m:GetHashCode() end
UnityEngine = {}
UnityEngine.AnimationCurve = m
return m