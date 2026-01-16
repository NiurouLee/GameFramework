---@class Cinemachine.CinemachineComponentBase : UnityEngine.MonoBehaviour
---@field VirtualCamera Cinemachine.CinemachineVirtualCameraBase
---@field FollowTarget UnityEngine.Transform
---@field LookAtTarget UnityEngine.Transform
---@field AbstractFollowTargetGroup Cinemachine.ICinemachineTargetGroup
---@field FollowTargetGroup Cinemachine.CinemachineTargetGroup
---@field FollowTargetPosition UnityEngine.Vector3
---@field FollowTargetRotation UnityEngine.Quaternion
---@field AbstractLookAtTargetGroup Cinemachine.ICinemachineTargetGroup
---@field LookAtTargetGroup Cinemachine.CinemachineTargetGroup
---@field LookAtTargetPosition UnityEngine.Vector3
---@field LookAtTargetRotation UnityEngine.Quaternion
---@field VcamState Cinemachine.CameraState
---@field IsValid bool
---@field Stage Cinemachine.CinemachineCore.Stage
---@field BodyAppliesAfterAim bool
local m = {}
---@param curState Cinemachine.CameraState
---@param deltaTime float
function m:PrePipelineMutateCameraState(curState, deltaTime) end
---@param curState Cinemachine.CameraState
---@param deltaTime float
function m:MutateCameraState(curState, deltaTime) end
---@param fromCam Cinemachine.ICinemachineCamera
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
---@param transitionParams Cinemachine.CinemachineVirtualCameraBase.TransitionParams
---@return bool
function m:OnTransitionFromCamera(fromCam, worldUp, deltaTime, transitionParams) end
---@param target UnityEngine.Transform
---@param positionDelta UnityEngine.Vector3
function m:OnTargetObjectWarped(target, positionDelta) end
---@param pos UnityEngine.Vector3
---@param rot UnityEngine.Quaternion
function m:ForceCameraPosition(pos, rot) end
---@return float
function m:GetMaxDampTime() end
Cinemachine = {}
Cinemachine.CinemachineComponentBase = m
return m