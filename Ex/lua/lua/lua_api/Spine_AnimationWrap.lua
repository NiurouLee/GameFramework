---@class Spine.Animation : object
---@field Timelines Spine.ExposedList
---@field Duration float
---@field Name string
local m = {}
---@param skeleton Spine.Skeleton
---@param lastTime float
---@param time float
---@param loop bool
---@param events Spine.ExposedList
---@param alpha float
---@param blend Spine.MixBlend
---@param direction Spine.MixDirection
function m:Apply(skeleton, lastTime, time, loop, events, alpha, blend, direction) end
---@return string
function m:ToString() end
Spine = {}
Spine.Animation = m
return m