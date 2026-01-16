---@class UnityEngine.RenderTexture : UnityEngine.Texture
---@field width int
---@field height int
---@field dimension UnityEngine.Rendering.TextureDimension
---@field useMipMap bool
---@field sRGB bool
---@field format UnityEngine.RenderTextureFormat
---@field vrUsage UnityEngine.VRTextureUsage
---@field memorylessMode UnityEngine.RenderTextureMemoryless
---@field autoGenerateMips bool
---@field volumeDepth int
---@field antiAliasing int
---@field bindTextureMS bool
---@field enableRandomWrite bool
---@field useDynamicScale bool
---@field isPowerOfTwo bool
---@field active UnityEngine.RenderTexture
---@field colorBuffer UnityEngine.RenderBuffer
---@field depthBuffer UnityEngine.RenderBuffer
---@field depth int
---@field descriptor UnityEngine.RenderTextureDescriptor
local m = {}
---@return System.IntPtr
function m:GetNativeDepthBufferPtr() end
---@overload fun():void
---@param discardColor bool
---@param discardDepth bool
function m:DiscardContents(discardColor, discardDepth) end
function m:MarkRestoreExpected() end
---@overload fun(target:UnityEngine.RenderTexture):void
function m:ResolveAntiAliasedSurface() end
---@param propertyName string
function m:SetGlobalShaderProperty(propertyName) end
---@return bool
function m:Create() end
function m:Release() end
---@return bool
function m:IsCreated() end
function m:GenerateMips() end
---@param equirect UnityEngine.RenderTexture
---@param eye UnityEngine.Camera.MonoOrStereoscopicEye
function m:ConvertToEquirect(equirect, eye) end
---@param rt UnityEngine.RenderTexture
---@return bool
function m.SupportsStencil(rt) end
---@param temp UnityEngine.RenderTexture
function m.ReleaseTemporary(temp) end
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, memorylessMode:UnityEngine.RenderTextureMemoryless, vrUsage:UnityEngine.VRTextureUsage, useDynamicScale:bool):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, memorylessMode:UnityEngine.RenderTextureMemoryless, vrUsage:UnityEngine.VRTextureUsage):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int, memorylessMode:UnityEngine.RenderTextureMemoryless):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite, antiAliasing:int):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat, readWrite:UnityEngine.RenderTextureReadWrite):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int, format:UnityEngine.RenderTextureFormat):UnityEngine.RenderTexture
---@overload fun(width:int, height:int, depthBuffer:int):UnityEngine.RenderTexture
---@overload fun(width:int, height:int):UnityEngine.RenderTexture
---@param desc UnityEngine.RenderTextureDescriptor
---@return UnityEngine.RenderTexture
function m.GetTemporary(desc) end
UnityEngine = {}
UnityEngine.RenderTexture = m
return m