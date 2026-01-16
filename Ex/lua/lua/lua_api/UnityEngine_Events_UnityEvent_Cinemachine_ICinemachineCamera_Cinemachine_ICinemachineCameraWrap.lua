---@class UnityEngine.Events.UnityEvent<Cinemachine.ICinemachineCamera,Cinemachine.ICinemachineCamera> : UnityEngine.Events.UnityEventBase
local m = {}
---@param call UnityEngine.Events.UnityAction
function m:AddListener(call) end
---@param call UnityEngine.Events.UnityAction
function m:RemoveListener(call) end
---@param arg0 Cinemachine.ICinemachineCamera
---@param arg1 Cinemachine.ICinemachineCamera
function m:Invoke(arg0, arg1) end
UnityEngine = {}
UnityEngine.Events = {}
UnityEngine.Events.UnityEvent<Cinemachine = {}
UnityEngine.Events.UnityEvent<Cinemachine.ICinemachineCamera,Cinemachine = {}
UnityEngine.Events.UnityEvent<Cinemachine.ICinemachineCamera,Cinemachine.ICinemachineCamera> = m
return m