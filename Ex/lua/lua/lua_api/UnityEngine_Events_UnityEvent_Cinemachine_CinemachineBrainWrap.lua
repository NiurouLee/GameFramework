---@class UnityEngine.Events.UnityEvent<Cinemachine.CinemachineBrain> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 Cinemachine.CinemachineBrain
function m:Invoke(arg0) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<Cinemachine = {}
UnityEngine.Events.UnityEvent<Cinemachine.CinemachineBrain> = m
return m