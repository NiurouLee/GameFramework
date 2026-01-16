---@class Cinemachine.CinemachineVirtualCameraBase : UnityEngine.MonoBehaviour
---@field ValidatingStreamVersion int
---@field FollowTargetAttachment float
---@field LookAtTargetAttachment float
---@field Name string
---@field Description string
---@field Priority int
---@field VirtualCameraGameObject UnityEngine.GameObject
---@field IsValid bool
---@field State Cinemachine.CameraState
---@field ParentCamera Cinemachine.ICinemachineCamera
---@field LookAt UnityEngine.Transform
---@field Follow UnityEngine.Transform
---@field PreviousStateIsValid bool
---@field m_ExcludedPropertiesInInspector table
---@field m_LockStageInInspector table
---@field m_Priority int
---@field m_StandbyUpdate Cinemachine.CinemachineVirtualCameraBase.StandbyUpdateMode
local m = {}
---@return float
function m:GetMaxDampTime() end
---@overload fun(initial:UnityEngine.Vector3, dampTime:UnityEngine.Vector3, deltaTime:float):UnityEngine.Vector3
---@overload fun(initial:UnityEngine.Vector3, dampTime:float, deltaTime:float):UnityEngine.Vector3
---@param initial float
---@param dampTime float
---@param deltaTime float
---@return float
function m:DetachedFollowTargetDamp(initial, dampTime, deltaTime) end
---@overload fun(initial:UnityEngine.Vector3, dampTime:UnityEngine.Vector3, deltaTime:float):UnityEngine.Vector3
---@overload fun(initial:UnityEngine.Vector3, dampTime:float, deltaTime:float):UnityEngine.Vector3
---@param initial float
---@param dampTime float
---@param deltaTime float
---@return float
function m:DetachedLookAtTargetDamp(initial, dampTime, deltaTime) end
---@param extension Cinemachine.CinemachineExtension
function m:AddExtension(extension) end
---@param extension Cinemachine.CinemachineExtension
function m:RemoveExtension(extension) end
---@param vcam Cinemachine.ICinemachineCamera
---@param dominantChildOnly bool
---@return bool
function m:IsLiveChild(vcam, dominantChildOnly) end
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:UpdateCameraState(worldUp, deltaTime) end
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:InternalUpdateCameraState(worldUp, deltaTime) end
---@param fromCam Cinemachine.ICinemachineCamera
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:OnTransitionFromCamera(fromCam, worldUp, deltaTime) end
---@return Cinemachine.AxisState.IInputAxisProvider
function m:GetInputAxisProvider() end
function m:MoveToTopOfPrioritySubqueue() end
---@param target UnityEngine.Transform
---@param positionDelta UnityEngine.Vector3
function m:OnTargetObjectWarped(target, positionDelta) end
---@param pos UnityEngine.Vector3
---@param rot UnityEngine.Quaternion
function m:ForceCameraPosition(pos, rot) end
Cinemachine = {}
Cinemachine.CinemachineVirtualCameraBase = m
return m