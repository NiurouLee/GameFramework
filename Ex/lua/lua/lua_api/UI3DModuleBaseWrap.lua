---@class UI3DModuleBase : UnityEngine.MonoBehaviour
---@field Params UI3DModuleParams
---@field GetH3D3DViewControl H3D3DViewControl
---@field m_model_parent UnityEngine.Transform
---@field m_3d_view_control H3D3DViewControl
---@field m_ui_component UIComponentFor3D
---@field m_strNameKey string
local m = {}
---@param uibaseDepth int
---@param offsetDepth int
function m:SetDepth(uibaseDepth, offsetDepth) end
UI3DModuleBase = m
return m