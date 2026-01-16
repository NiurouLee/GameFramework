---@class Cinemachine.CinemachineBlend : object
---@field CamA Cinemachine.ICinemachineCamera
---@field CamB Cinemachine.ICinemachineCamera
---@field BlendCurve UnityEngine.AnimationCurve
---@field TimeInBlend float
---@field BlendWeight float
---@field IsValid bool
---@field Duration float
---@field IsComplete bool
---@field Description string
---@field State Cinemachine.CameraState
local m = {}
---@param cam Cinemachine.ICinemachineCamera
---@return bool
function m:Uses(cam) end
---@param worldUp UnityEngine.Vector3
---@param deltaTime float
function m:UpdateCameraState(worldUp, deltaTime) end
Cinemachine = {}
Cinemachine.CinemachineBlend = m
return m