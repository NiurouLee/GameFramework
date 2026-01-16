---@class Spine.TrackEntry : object
---@field TrackIndex int
---@field Animation Spine.Animation
---@field Loop bool
---@field Delay float
---@field TrackTime float
---@field TrackEnd float
---@field AnimationStart float
---@field AnimationEnd float
---@field AnimationLast float
---@field AnimationTime float
---@field TimeScale float
---@field Alpha float
---@field EventThreshold float
---@field AttachmentThreshold float
---@field DrawOrderThreshold float
---@field Next Spine.TrackEntry
---@field IsComplete bool
---@field MixTime float
---@field MixDuration float
---@field MixBlend Spine.MixBlend
---@field MixingFrom Spine.TrackEntry
---@field MixingTo Spine.TrackEntry
---@field HoldPrevious bool
local m = {}
function m:Reset() end
function m:ResetRotationDirections() end
---@return string
function m:ToString() end
Spine = {}
Spine.TrackEntry = m
return m