---@class UnityEngine.ReflectionProbe : UnityEngine.Behaviour
---@field size UnityEngine.Vector3
---@field center UnityEngine.Vector3
---@field nearClipPlane float
---@field farClipPlane float
---@field intensity float
---@field bounds UnityEngine.Bounds
---@field hdr bool
---@field shadowDistance float
---@field resolution int
---@field cullingMask int
---@field clearFlags UnityEngine.Rendering.ReflectionProbeClearFlags
---@field backgroundColor UnityEngine.Color
---@field blendDistance float
---@field boxProjection bool
---@field mode UnityEngine.Rendering.ReflectionProbeMode
---@field importance int
---@field refreshMode UnityEngine.Rendering.ReflectionProbeRefreshMode
---@field timeSlicingMode UnityEngine.Rendering.ReflectionProbeTimeSlicingMode
---@field bakedTexture UnityEngine.Texture
---@field customBakedTexture UnityEngine.Texture
---@field realtimeTexture UnityEngine.RenderTexture
---@field texture UnityEngine.Texture
---@field textureHDRDecodeValues UnityEngine.Vector4
---@field minBakedCubemapResolution int
---@field maxBakedCubemapResolution int
---@field defaultTextureHDRDecodeValues UnityEngine.Vector4
---@field defaultTexture UnityEngine.Texture
local m = {}
function m:Reset() end
---@overload fun(targetTexture:UnityEngine.RenderTexture):int
---@return int
function m:RenderProbe() end
---@param renderId int
---@return bool
function m:IsFinishedRendering(renderId) end
---@param src UnityEngine.Texture
---@param dst UnityEngine.Texture
---@param blend float
---@param target UnityEngine.RenderTexture
---@return bool
function m.BlendCubemap(src, dst, blend, target) end
UnityEngine = {}
UnityEngine.ReflectionProbe = m
return m