---@class Cinemachine.CinemachineTransposer : Cinemachine.CinemachineComponentBase
---@field HideOffsetInInspector bool
---@field EffectiveOffset UnityEngine.Vector3
---@field IsValid bool
---@field Stage Cinemachine.CinemachineCore.Stage
---@field m_BindingMode Cinemachine.CinemachineTransposer.BindingMode
---@field m_FollowOffset UnityEngine.Vector3
---@field m_XDamping float
---@field m_YDamping float
---@field m_ZDamping float
---@field m_AngularDampingMode Cinemachine.CinemachineTransposer.AngularDampingMode
---@field m_PitchDamping float
---@field m_YawDamping float
---@field m_RollDamping float
---@field m_AngularDamping float
local m = {}
---@return float
function m:GetMaxDampTime() end
---@param curState Cinemachine.CameraState
---@param deltaTime float
function m:MutateCameraState(curState, deltaTime) end
---@param target UnityEngine.Transform
---@param positionDelta UnityEngine.Vector3
function m:OnTargetObjectWarped(target, positionDelta) end
---@param pos UnityEngine.Vector3
---@param rot UnityEngine.Quaternion
function m:ForceCameraPosition(pos, rot) end
---@param worldUp UnityEngine.Vector3
---@return UnityEngine.Vector3
function m:GetTargetCameraPosition(worldUp) end
---@param worldUp UnityEngine.Vector3
---@return UnityEngine.Quaternion
function m:GetReferenceOrientation(worldUp) end
Cinemachine = {}
Cinemachine.CinemachineTransposer = m
return m