---@class UnityEngine.SystemInfo : object
---@field batteryLevel float
---@field batteryStatus UnityEngine.BatteryStatus
---@field operatingSystem string
---@field operatingSystemFamily UnityEngine.OperatingSystemFamily
---@field processorType string
---@field processorFrequency int
---@field processorCount int
---@field systemMemorySize int
---@field deviceUniqueIdentifier string
---@field deviceName string
---@field deviceModel string
---@field supportsAccelerometer bool
---@field supportsGyroscope bool
---@field supportsLocationService bool
---@field supportsVibration bool
---@field supportsAudio bool
---@field deviceType UnityEngine.DeviceType
---@field graphicsMemorySize int
---@field graphicsDeviceName string
---@field graphicsDeviceVendor string
---@field graphicsDeviceID int
---@field graphicsDeviceVendorID int
---@field graphicsDeviceType UnityEngine.Rendering.GraphicsDeviceType
---@field graphicsUVStartsAtTop bool
---@field graphicsDeviceVersion string
---@field graphicsShaderLevel int
---@field graphicsMultiThreaded bool
---@field hasHiddenSurfaceRemovalOnGPU bool
---@field hasDynamicUniformArrayIndexingInFragmentShaders bool
---@field supportsShadows bool
---@field supportsRawShadowDepthSampling bool
---@field supportsMotionVectors bool
---@field supportsRenderToCubemap bool
---@field supportsImageEffects bool
---@field supports3DTextures bool
---@field supports2DArrayTextures bool
---@field supports3DRenderTextures bool
---@field supportsCubemapArrayTextures bool
---@field copyTextureSupport UnityEngine.Rendering.CopyTextureSupport
---@field supportsComputeShaders bool
---@field supportsInstancing bool
---@field supportsHardwareQuadTopology bool
---@field supports32bitsIndexBuffer bool
---@field supportsSparseTextures bool
---@field supportedRenderTargetCount int
---@field supportsSeparatedRenderTargetsBlend bool
---@field supportsMultisampledTextures int
---@field supportsMultisampleAutoResolve bool
---@field supportsTextureWrapMirrorOnce int
---@field usesReversedZBuffer bool
---@field npotSupport UnityEngine.NPOTSupport
---@field maxTextureSize int
---@field maxCubemapSize int
---@field supportsAsyncCompute bool
---@field supportsGPUFence bool
---@field supportsAsyncGPUReadback bool
---@field supportsMipStreaming bool
---@field unsupportedIdentifier string
local m = {}
---@param format UnityEngine.RenderTextureFormat
---@return bool
function m.SupportsRenderTextureFormat(format) end
---@param format UnityEngine.RenderTextureFormat
---@return bool
function m.SupportsBlendingOnRenderTextureFormat(format) end
---@param format UnityEngine.TextureFormat
---@return bool
function m.SupportsTextureFormat(format) end
---@param format UnityEngine.Experimental.Rendering.GraphicsFormat
---@param usage UnityEngine.Experimental.Rendering.FormatUsage
---@return bool
function m.IsFormatSupported(format, usage) end
UnityEngine = {}
UnityEngine.SystemInfo = m
return m