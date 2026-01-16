---@class EffectLoader : UnityEngine.MonoBehaviour
---@field m_asyncLoad bool
---@field mOnAysncLoad System.Action
local m = {}
---@param effectName string
function m:LoadEffect(effectName) end
---@param effectName string
---@param onAysncLoad System.Action
function m:AsyncLoadEffect(effectName, onAysncLoad) end
function m:DestroyCurrentEffect() end
EffectLoader = m
return m