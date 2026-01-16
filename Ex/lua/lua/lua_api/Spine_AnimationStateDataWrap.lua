---@class Spine.AnimationStateData : object
---@field SkeletonData Spine.SkeletonData
---@field DefaultMix float
local m = {}
---@overload fun(from:Spine.Animation, to:Spine.Animation, duration:float):void
---@param fromName string
---@param toName string
---@param duration float
function m:SetMix(fromName, toName, duration) end
---@param from Spine.Animation
---@param to Spine.Animation
---@return float
function m:GetMix(from, to) end
Spine = {}
Spine.AnimationStateData = m
return m