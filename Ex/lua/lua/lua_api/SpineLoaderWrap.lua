---@class SpineLoader : UnityEngine.MonoBehaviour
---@field CurrentSkeleton Spine.Unity.SkeletonGraphic
---@field CurrentMultiSkeleton Spine.Unity.Modules.SkeletonGraphicMultiObject
---@field AnimationState Spine.AnimationState
---@field m_asyncLoad bool
---@field color UnityEngine.Color
---@field mOnAysncLoad System.Action
local m = {}
---@param spineName string
function m:LoadSpine(spineName) end
---@param spineName string
---@param onAysncLoad System.Action
function m:AsyncLoadSpine(spineName, onAysncLoad) end
---@param trackIndex int
---@param animationName string
---@param loop bool
function m:SetAnimation(trackIndex, animationName, loop) end
function m:DestroyCurrentSpine() end
SpineLoader = m
return m