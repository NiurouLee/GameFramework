---@class FocusCameraEffect : UnityEngine.MonoBehaviour
---@field mBackgroundMaterial UnityEngine.Material
local m = {}
---@param mainCamera UnityEngine.Camera
function m:Initialize(mainCamera) end
---@overload fun(targetBrightness:float):void
---@param targetBrightness float
---@param duration float
function m:SetTargetBrightness(targetBrightness, duration) end
---@param progress float
function m:SetProgress(progress) end
FocusCameraEffect = m
return m