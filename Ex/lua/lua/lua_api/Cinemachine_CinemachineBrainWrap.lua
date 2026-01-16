---@class Cinemachine.CinemachineBrain : UnityEngine.MonoBehaviour
---@field OutputCamera UnityEngine.Camera
---@field SoloCamera Cinemachine.ICinemachineCamera
---@field DefaultWorldUp UnityEngine.Vector3
---@field ActiveVirtualCamera Cinemachine.ICinemachineCamera
---@field IsBlending bool
---@field ActiveBlend Cinemachine.CinemachineBlend
---@field CurrentCameraState Cinemachine.CameraState
---@field m_ShowDebugText bool
---@field m_ShowCameraFrustum bool
---@field m_IgnoreTimeScale bool
---@field m_WorldUpOverride UnityEngine.Transform
---@field m_UpdateMethod Cinemachine.CinemachineBrain.UpdateMethod
---@field m_BlendUpdateMethod Cinemachine.CinemachineBrain.BrainUpdateMethod
---@field m_DefaultBlend Cinemachine.CinemachineBlendDefinition
---@field m_CustomBlends Cinemachine.CinemachineBlenderSettings
---@field m_CameraCutEvent Cinemachine.CinemachineBrain.BrainEvent
---@field m_CameraActivatedEvent Cinemachine.CinemachineBrain.VcamActivatedEvent
local m = {}
---@return UnityEngine.Color
function m.GetSoloGUIColor() end
function m:ManualUpdate() end
---@param overrideId int
---@param camA Cinemachine.ICinemachineCamera
---@param camB Cinemachine.ICinemachineCamera
---@param weightB float
---@param deltaTime float
---@return int
function m:SetCameraOverride(overrideId, camA, camB, weightB, deltaTime) end
---@param overrideId int
function m:ReleaseCameraOverride(overrideId) end
---@param outputBlend Cinemachine.CinemachineBlend
---@param numTopLayersToExclude int
function m:ComputeCurrentBlend(outputBlend, numTopLayersToExclude) end
---@param vcam Cinemachine.ICinemachineCamera
---@param dominantChildOnly bool
---@return bool
function m:IsLive(vcam, dominantChildOnly) end
Cinemachine = {}
Cinemachine.CinemachineBrain = m
return m