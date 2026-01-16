---@class Cinemachine.CinemachineVirtualCamera : Cinemachine.CinemachineVirtualCameraBase
---@field State Cinemachine.CameraState
---@field LookAt UnityEngine.Transform
---@field Follow UnityEngine.Transform
---@field UserIsDragging bool
---@field m_LookAt UnityEngine.Transform
---@field m_Follow UnityEngine.Transform
---@field m_Lens Cinemachine.LensSettings
---@field m_Transitions Cinemachine.CinemachineVirtualCameraBase.TransitionParams
---@field PipelineName string
---@field CreatePipelineOverride Cinemachine.CinemachineVirtualCamera.CreatePipelineDelegate
---@field DestroyPipelineOverride Cinemachine.CinemachineVirtualCamera.DestroyPipelineDelegate
---@field m_ExcludedPropertiesInInspector table
---@field m_LockStageInInspector table
---@field m_Priority int
---@field m_StandbyUpdate Cinemachine.CinemachineVirtualCameraBase.StandbyUpdateMode
local m = {}
---@return float
function m:GetMaxDampTime() end
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:InternalUpdateCameraState(worldUp, deltaTime) end
function m:InvalidateComponentPipeline() end
---@return UnityEngine.Transform
function m:GetComponentOwner() end
---@return table
function m:GetComponentPipeline() end
---@param stage Cinemachine.CinemachineCore.Stage
---@return Cinemachine.CinemachineComponentBase
function m:GetCinemachineComponent(stage) end
---@param target UnityEngine.Transform
---@param positionDelta UnityEngine.Vector3
function m:OnTargetObjectWarped(target, positionDelta) end
---@param pos UnityEngine.Vector3
---@param rot UnityEngine.Quaternion
function m:ForceCameraPosition(pos, rot) end
---@param fromCam Cinemachine.ICinemachineCamera
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:OnTransitionFromCamera(fromCam, worldUp, deltaTime) end
Cinemachine = {}
Cinemachine.CinemachineVirtualCamera = m
return m