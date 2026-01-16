---@class UnityEngine.Events.UnityEvent<bool> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 bool
function m:Invoke(arg0) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<bool> = m
return m