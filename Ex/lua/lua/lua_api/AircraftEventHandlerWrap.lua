---@class AircraftEventHandler : UnityEngine.MonoBehaviour
---@field events table
local m = {}
---@param clip UnityEngine.AnimationClip
function m:OnClipAdded(clip) end
---@param clip UnityEngine.AnimationClip
function m:OnClipRemoved(clip) end
---@param idx int
function m:Show(idx) end
---@param idx int
function m:Hide(idx) end
---@param clip string
---@param time float
function m:TriggerByTime(clip, time) end
AircraftEventHandler = m
return m