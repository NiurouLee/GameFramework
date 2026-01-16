---@class UnityEngine.Video.VideoClip : UnityEngine.Object
---@field originalPath string
---@field frameCount ulong
---@field frameRate double
---@field length double
---@field width uint
---@field height uint
---@field pixelAspectRatioNumerator uint
---@field pixelAspectRatioDenominator uint
---@field audioTrackCount ushort
local m = {}
---@param audioTrackIdx ushort
---@return ushort
function m:GetAudioChannelCount(audioTrackIdx) end
---@param audioTrackIdx ushort
---@return uint
function m:GetAudioSampleRate(audioTrackIdx) end
---@param audioTrackIdx ushort
---@return string
function m:GetAudioLanguage(audioTrackIdx) end
UnityEngine = {}
UnityEngine.Video = {}
UnityEngine.Video.VideoClip = m
return m