---@class UnityEngine.Events.UnityEvent<UnityEngine.Vector2> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 UnityEngine.Vector2
function m:Invoke(arg0) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<UnityEngine = {}
UnityEngine.Events.UnityEvent<UnityEngine.Vector2> = m
return m