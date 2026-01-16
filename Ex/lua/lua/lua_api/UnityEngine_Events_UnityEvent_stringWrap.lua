---@class UnityEngine.Events.UnityEvent<string> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 string
function m:Invoke(arg0) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<string> = m
return m