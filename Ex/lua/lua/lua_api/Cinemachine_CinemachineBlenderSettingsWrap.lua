---@class Cinemachine.CinemachineBlenderSettings : UnityEngine.ScriptableObject
---@field m_CustomBlends table
---@field kBlendFromAnyCameraLabel string
local m = {}
---@param fromCameraName string
---@param toCameraName string
---@param defaultBlend Cinemachine.CinemachineBlendDefinition
---@return Cinemachine.CinemachineBlendDefinition
function m:GetBlendForVirtualCameras(fromCameraName, toCameraName, defaultBlend) end
Cinemachine = {}
Cinemachine.CinemachineBlenderSettings = m
return m