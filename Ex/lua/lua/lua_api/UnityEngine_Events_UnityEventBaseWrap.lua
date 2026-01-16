---@class UnityEngine.Events.UnityEventBase : object
local m = {}
---@return int
function m:GetPersistentEventCount() end
---@param index int
---@return UnityEngine.Object
function m:GetPersistentTarget(index) end
---@param index int
---@return string
function m:GetPersistentMethodName(index) end
---@param index int
---@param state UnityEngine.Events.UnityEventCallState
function m:SetPersistentListenerState(index, state) end
function m:RemoveAllListeners() end
---@return string
function m:ToString() end
---@param obj object
---@param functionName string
---@param argumentTypes table
---@return System.Reflection.MethodInfo
function m.GetValidMethodInfo(obj, functionName, argumentTypes) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEventBase = m
return m