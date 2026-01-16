---@class FadeComponent : UnityEngine.MonoBehaviour
---@field viewType ActorViewType
---@field Alpha float
---@field isEnableOutLine bool
---@field IsGhost bool
---@field isDotSelected bool
---@field Speed float
---@field s_OutLineLayer string
---@field s_DetailTexPath string
---@field s_SelectedDotShader string
---@field s_SelectedFaceShader string
---@field s_GhostShaderName string
---@field s_GhostFaceShaderName string
---@field _OutLineColor int
---@field _EffectColor int
---@field _DetailColor int
---@field _DetailTex int
---@field _ScaleParam int
---@field _RimColor int
---@field m_ViewType ActorViewType
local m = {}
function m:UpdateSelectedParams() end
---@param id int
---@param c UnityEngine.Color
function m:ChangeColor(id, c) end
function m:UpdatGhostColor() end
function m:UpdateOutlineColor() end
---@param duration float
function m:RimFlash(duration) end
function m:RefreshData() end
function m:CollectMaterials() end
function m:CollectAnimators() end
function m:CollectPSs() end
FadeComponent = m
return m