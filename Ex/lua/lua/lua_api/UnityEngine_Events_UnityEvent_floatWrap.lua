---@class UnityEngine.Events.UnityEvent<float> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 float
function m:Invoke(arg0) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<float> = m
return m