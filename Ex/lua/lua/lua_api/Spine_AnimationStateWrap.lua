---@class Spine.AnimationState : object
---@field TimeScale float
---@field Data Spine.AnimationStateData
---@field Tracks Spine.ExposedList
local m = {}
---@param time float
function m:Seek(time) end
---@param delta float
function m:Update(delta) end
---@param skeleton Spine.Skeleton
---@return bool
function m:Apply(skeleton) end
function m:ClearTracks() end
---@param trackIndex int
function m:ClearTrack(trackIndex) end
---@overload fun(trackIndex:int, animation:Spine.Animation, loop:bool):Spine.TrackEntry
---@param trackIndex int
---@param animationName string
---@param loop bool
---@return Spine.TrackEntry
function m:SetAnimation(trackIndex, animationName, loop) end
---@overload fun(trackIndex:int, animation:Spine.Animation, loop:bool, delay:float):Spine.TrackEntry
---@param trackIndex int
---@param animationName string
---@param loop bool
---@param delay float
---@return Spine.TrackEntry
function m:AddAnimation(trackIndex, animationName, loop, delay) end
---@param trackIndex int
---@param mixDuration float
---@return Spine.TrackEntry
function m:SetEmptyAnimation(trackIndex, mixDuration) end
---@param trackIndex int
---@param mixDuration float
---@param delay float
---@return Spine.TrackEntry
function m:AddEmptyAnimation(trackIndex, mixDuration, delay) end
---@param mixDuration float
function m:SetEmptyAnimations(mixDuration) end
---@param trackIndex int
---@return Spine.TrackEntry
function m:GetCurrent(trackIndex) end
function m:ClearListenerNotifications() end
---@return string
function m:ToString() end
Spine = {}
Spine.AnimationState = m
return m