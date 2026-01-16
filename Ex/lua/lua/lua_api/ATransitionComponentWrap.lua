---@class ATransitionComponent : UnityEngine.MonoBehaviour
---@field EnterTime float
---@field RestTime float
local m = {}
---@param anim string
---@param endFrame float
function m:ChangeAnim(anim, endFrame) end
---@param playing bool
function m:PlayEnterAnimation(playing) end
---@param playing bool
function m:PlayLeaveAnimation(playing) end
ATransitionComponent = m
return m