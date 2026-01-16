---@class UnityEngine.Video.VideoPlayer : UnityEngine.Behaviour
---@field source UnityEngine.Video.VideoSource
---@field url string
---@field clip UnityEngine.Video.VideoClip
---@field renderMode UnityEngine.Video.VideoRenderMode
---@field targetCamera UnityEngine.Camera
---@field targetTexture UnityEngine.RenderTexture
---@field targetMaterialRenderer UnityEngine.Renderer
---@field targetMaterialProperty string
---@field aspectRatio UnityEngine.Video.VideoAspectRatio
---@field targetCameraAlpha float
---@field targetCamera3DLayout UnityEngine.Video.Video3DLayout
---@field texture UnityEngine.Texture
---@field isPrepared bool
---@field waitForFirstFrame bool
---@field playOnAwake bool
---@field isPlaying bool
---@field isPaused bool
---@field canSetTime bool
---@field time double
---@field frame long
---@field clockTime double
---@field canStep bool
---@field canSetPlaybackSpeed bool
---@field playbackSpeed float
---@field isLooping bool
---@field canSetTimeSource bool
---@field timeSource UnityEngine.Video.VideoTimeSource
---@field timeReference UnityEngine.Video.VideoTimeReference
---@field externalReferenceTime double
---@field canSetSkipOnDrop bool
---@field skipOnDrop bool
---@field frameCount ulong
---@field frameRate float
---@field length double
---@field width uint
---@field height uint
---@field pixelAspectRatioNumerator uint
---@field pixelAspectRatioDenominator uint
---@field audioTrackCount ushort
---@field controlledAudioTrackMaxCount ushort
---@field controlledAudioTrackCount ushort
---@field audioOutputMode UnityEngine.Video.VideoAudioOutputMode
---@field canSetDirectAudioVolume bool
---@field sendFrameReadyEvents bool
local m = {}
function m:Prepare() end
function m:Play() end
function m:Pause() end
function m:Stop() end
function m:StepForward() end
---@param trackIndex ushort
---@return string
function m:GetAudioLanguageCode(trackIndex) end
---@param trackIndex ushort
---@return ushort
function m:GetAudioChannelCount(trackIndex) end
---@param trackIndex ushort
---@return uint
function m:GetAudioSampleRate(trackIndex) end
---@param trackIndex ushort
---@param enabled bool
function m:EnableAudioTrack(trackIndex, enabled) end
---@param trackIndex ushort
---@return bool
function m:IsAudioTrackEnabled(trackIndex) end
---@param trackIndex ushort
---@return float
function m:GetDirectAudioVolume(trackIndex) end
---@param trackIndex ushort
---@param volume float
function m:SetDirectAudioVolume(trackIndex, volume) end
---@param trackIndex ushort
---@return bool
function m:GetDirectAudioMute(trackIndex) end
---@param trackIndex ushort
---@param mute bool
function m:SetDirectAudioMute(trackIndex, mute) end
---@param trackIndex ushort
---@return UnityEngine.AudioSource
function m:GetTargetAudioSource(trackIndex) end
---@param trackIndex ushort
---@param source UnityEngine.AudioSource
function m:SetTargetAudioSource(trackIndex, source) end
UnityEngine = {}
UnityEngine.Video = {}
UnityEngine.Video.VideoPlayer = m
return m