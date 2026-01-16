---@class UnityEngine.H3DPostProcessing.PostProcessing : UnityEngine.MonoBehaviour
---@field profile UnityEngine.H3DPostProcessing.PostProcessingProfile
---@field jitteredMatrixFunc System.Func
local m = {}
---@param isActive bool
function m:SetTiltShiftActive(isActive) end
function m:ResetTemporalEffects() end
---@param enabled bool
function m:SetBloomEnable(enabled) end
UnityEngine = {}
UnityEngine.H3DPostProcessing = {}
UnityEngine.H3DPostProcessing.PostProcessing = m
return m