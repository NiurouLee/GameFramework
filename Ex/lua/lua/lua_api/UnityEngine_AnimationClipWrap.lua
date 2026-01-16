---@class UnityEngine.AnimationClip : UnityEngine.Object
---@field events table
---@field length float
---@field frameRate float
---@field wrapMode UnityEngine.WrapMode
---@field localBounds UnityEngine.Bounds
---@field legacy bool
---@field humanMotion bool
---@field empty bool
---@field hasGenericRootTransform bool
---@field hasMotionFloatCurves bool
---@field hasMotionCurves bool
---@field hasRootCurves bool
local m = {}
---@param evt UnityEngine.AnimationEvent
function m:AddEvent(evt) end
---@param go UnityEngine.GameObject
---@param time float
function m:SampleAnimation(go, time) end
---@param relativePath string
---@param type System.Type
---@param propertyName string
---@param curve UnityEngine.AnimationCurve
function m:SetCurve(relativePath, type, propertyName, curve) end
function m:EnsureQuaternionContinuity() end
function m:ClearCurves() end
UnityEngine = {}
UnityEngine.AnimationClip = m
return m