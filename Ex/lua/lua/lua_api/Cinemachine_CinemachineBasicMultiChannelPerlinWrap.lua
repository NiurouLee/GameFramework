---@class Cinemachine.CinemachineBasicMultiChannelPerlin : Cinemachine.CinemachineComponentBase
---@field IsValid bool
---@field Stage Cinemachine.CinemachineCore.Stage
---@field m_NoiseProfile Cinemachine.NoiseSettings
---@field m_PivotOffset UnityEngine.Vector3
---@field m_AmplitudeGain float
---@field m_FrequencyGain float
local m = {}
---@param curState Cinemachine.CameraState
---@param deltaTime float
function m:MutateCameraState(curState, deltaTime) end
function m:ReSeed() end
Cinemachine = {}
Cinemachine.CinemachineBasicMultiChannelPerlin = m
return m