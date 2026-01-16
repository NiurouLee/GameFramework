---@class TrailsFX.TrailEffectEx : UnityEngine.MonoBehaviour
---@field active bool
---@field ignoreStartFrames int
---@field duration float
---@field continuous bool
---@field smooth bool
---@field checkWorldPosition bool
---@field minDistance float
---@field minPixelDistance int
---@field stepsBufferSize int
---@field maxStepsPerFrame int
---@field checkTime bool
---@field timeInterval float
---@field offset UnityEngine.Vector3
---@field colorStartPalette UnityEngine.Gradient
---@field colorCycleDuration float
---@field maxBatches int
---@field meshPoolSize int
---@field timeTrailCurve UnityEngine.AnimationCurve
---@field distanceTrailCurve UnityEngine.AnimationCurve
---@field scaleOverTime UnityEngine.AnimationCurve
---@field floatValue float
---@field profile TrailsFX.TrailEffectExProfile
---@field trailMaterial UnityEngine.Material
---@field enableGPUInstancing bool
---@field followAvatarAnimation bool
---@field followAvatarPosition bool
---@field cam UnityEngine.Camera
local m = {}
function m:CheckEditorSettings() end
---@param profile TrailsFX.TrailEffectExProfile
function m:SetProfile(profile) end
function m:StoreRenderer() end
function m:Clear() end
function m:UpdateTrailProperties() end
TrailsFX = {}
TrailsFX.TrailEffectEx = m
return m