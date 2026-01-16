---@class OutlineComponent : UnityEngine.MonoBehaviour
---@field downSample int
---@field blurNum int
---@field outlinColor UnityEngine.Color
---@field intensity float
---@field outlineSize float
---@field blendType OutlineComponent.BlendType
---@field m_CustomCamera UnityEngine.Camera
---@field cutoff float
local m = {}
function m:SetDirty() end
OutlineComponent = m
return m