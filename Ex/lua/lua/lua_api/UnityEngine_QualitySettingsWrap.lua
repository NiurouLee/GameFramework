---@class UnityEngine.QualitySettings : UnityEngine.Object
---@field pixelLightCount int
---@field shadows UnityEngine.ShadowQuality
---@field shadowProjection UnityEngine.ShadowProjection
---@field shadowCascades int
---@field shadowDistance float
---@field shadowResolution UnityEngine.ShadowResolution
---@field shadowmaskMode UnityEngine.ShadowmaskMode
---@field shadowNearPlaneOffset float
---@field shadowCascade2Split float
---@field shadowCascade4Split UnityEngine.Vector3
---@field lodBias float
---@field anisotropicFiltering UnityEngine.AnisotropicFiltering
---@field masterTextureLimit int
---@field maximumLODLevel int
---@field particleRaycastBudget int
---@field softParticles bool
---@field softVegetation bool
---@field vSyncCount int
---@field antiAliasing int
---@field asyncUploadTimeSlice int
---@field asyncUploadBufferSize int
---@field asyncUploadPersistentBuffer bool
---@field realtimeReflectionProbes bool
---@field billboardsFaceCameraPosition bool
---@field resolutionScalingFixedDPIFactor float
---@field blendWeights UnityEngine.BlendWeights
---@field streamingMipmapsActive bool
---@field streamingMipmapsMemoryBudget float
---@field streamingMipmapsAddAllCameras bool
---@field streamingMipmapsMaxFileIORequests int
---@field maxQueuedFrames int
---@field names table
---@field desiredColorSpace UnityEngine.ColorSpace
---@field activeColorSpace UnityEngine.ColorSpace
local m = {}
---@overload fun():void
---@param applyExpensiveChanges bool
function m.IncreaseLevel(applyExpensiveChanges) end
---@overload fun():void
---@param applyExpensiveChanges bool
function m.DecreaseLevel(applyExpensiveChanges) end
---@overload fun(index:int, applyExpensiveChanges:bool):void
---@param index int
function m.SetQualityLevel(index) end
---@return int
function m.GetQualityLevel() end
UnityEngine = {}
UnityEngine.QualitySettings = m
return m