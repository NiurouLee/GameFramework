---@class H3DRenderSetting : UnityEngine.MonoBehaviour
---@field CustomLight UnityEngine.Transform
---@field ShadowPlane UnityEngine.Transform
---@field CustomShadow UnityEngine.Transform
---@field CameraPostion UnityEngine.Transform
---@field ShadowColor UnityEngine.Color
---@field EnableHighFog bool
---@field FlogColor UnityEngine.Color
---@field FogStart float
---@field FogEnd float
---@field SpecularBake bool
---@field SpecularFactor float
---@field BackIntensity float
---@field LineIntensity float
---@field EnableCellClip bool
---@field MutilAspectCell bool
---@field ClipParam UnityEngine.Vector4
---@field Profile UnityEngine.H3DPostProcessing.PostProcessingProfile
---@field CustomLightForwardIntro UnityEngine.Vector3
---@field CustomLightForwardBattle UnityEngine.Vector3
---@field CustomShadowForwardIntro UnityEngine.Vector3
---@field CustomShadowForwardBattle UnityEngine.Vector3
local m = {}
function m:UpdateGlobalParam() end
function m:SaveCustomLightForwardForIntro() end
function m:SaveCustomLightForwardForBattle() end
function m:SaveCustomShadowForwardForIntro() end
function m:SaveCustomShadowForwardForBattle() end
H3DRenderSetting = m
return m