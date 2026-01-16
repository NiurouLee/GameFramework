---@class UnityEngine.Renderer : UnityEngine.Component
---@field bounds UnityEngine.Bounds
---@field enabled bool
---@field isVisible bool
---@field shadowCastingMode UnityEngine.Rendering.ShadowCastingMode
---@field receiveShadows bool
---@field motionVectorGenerationMode UnityEngine.MotionVectorGenerationMode
---@field lightProbeUsage UnityEngine.Rendering.LightProbeUsage
---@field reflectionProbeUsage UnityEngine.Rendering.ReflectionProbeUsage
---@field renderingLayerMask uint
---@field rendererPriority int
---@field sortingLayerName string
---@field sortingLayerID int
---@field sortingOrder int
---@field allowOcclusionWhenDynamic bool
---@field isPartOfStaticBatch bool
---@field worldToLocalMatrix UnityEngine.Matrix4x4
---@field localToWorldMatrix UnityEngine.Matrix4x4
---@field lightProbeProxyVolumeOverride UnityEngine.GameObject
---@field probeAnchor UnityEngine.Transform
---@field lightmapIndex int
---@field realtimeLightmapIndex int
---@field lightmapScaleOffset UnityEngine.Vector4
---@field realtimeLightmapScaleOffset UnityEngine.Vector4
---@field materials table
---@field material UnityEngine.Material
---@field sharedMaterial UnityEngine.Material
---@field sharedMaterials table
local m = {}
---@return bool
function m:HasPropertyBlock() end
---@overload fun(properties:UnityEngine.MaterialPropertyBlock, materialIndex:int):void
---@param properties UnityEngine.MaterialPropertyBlock
function m:SetPropertyBlock(properties) end
---@overload fun(properties:UnityEngine.MaterialPropertyBlock, materialIndex:int):void
---@param properties UnityEngine.MaterialPropertyBlock
function m:GetPropertyBlock(properties) end
---@param m table
function m:GetMaterials(m) end
---@param m table
function m:GetSharedMaterials(m) end
---@param result table
function m:GetClosestReflectionProbes(result) end
UnityEngine = {}
UnityEngine.Renderer = m
return m