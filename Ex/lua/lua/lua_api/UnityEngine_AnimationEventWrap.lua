---@class UnityEngine.AnimationEvent : object
---@field stringParameter string
---@field floatParameter float
---@field intParameter int
---@field objectReferenceParameter UnityEngine.Object
---@field functionName string
---@field time float
---@field messageOptions UnityEngine.SendMessageOptions
---@field isFiredByLegacy bool
---@field isFiredByAnimator bool
---@field animationState UnityEngine.AnimationState
---@field animatorStateInfo UnityEngine.AnimatorStateInfo
---@field animatorClipInfo UnityEngine.AnimatorClipInfo
local m = {}
UnityEngine = {}
UnityEngine.AnimationEvent = m
return m