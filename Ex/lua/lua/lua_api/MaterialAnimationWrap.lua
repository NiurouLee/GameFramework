---@class MaterialAnimation : UnityEngine.MonoBehaviour
---@field warpMode ClipRunWrapMode
---@field clip MaterialAnimationClip
---@field allClips table
---@field clipPlayers table
---@field isForceCollectRenders bool
---@field isPlaying bool
---@field playedTime float
---@field isApplyAllRenders bool
---@field playAutomatically bool
local m = {}
---@param container MaterialAnimationContainer
function m:AddClips(container) end
---@param clip MaterialAnimationClip
---@param newName string
function m:AddClip(clip, newName) end
---@overload fun(clipName:string):void
---@param clip MaterialAnimationClip
function m:RemoveClip(clip) end
function m:ForceCollectRenders() end
---@overload fun(clipName:string):bool
---@overload fun(clipName:string, layer:int):bool
---@return bool
function m:Play() end
function m:Update() end
---@overload fun(clipName:string):void
function m:Stop() end
function m:StopAll() end
---@param layer int
function m:StopLayer(layer) end
---@param clipName string
---@return bool
function m:IsPlaying(clipName) end
---@param layer int
---@return float
function m:GetPlayedTime(layer) end
MaterialAnimation = m
return m