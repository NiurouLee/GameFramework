---@class UI3DModule : UI3DModuleBase
---@field m_model_parent UnityEngine.Transform
---@field m_3d_view_control H3D3DViewControl
---@field m_ui_component UIComponentFor3D
---@field m_strNameKey string
local m = {}
---@param _3d_model_prefab_path string
---@param limitRotateAngle float
function m:Init(_3d_model_prefab_path, limitRotateAngle) end
function m:Release() end
---@param camPfbPath string
---@param max_fov float
---@param ui_operation_graphic EmptyImage
---@param uibaseDepth int
---@param isCanUpDown bool
---@param isCanScale bool
---@param isCanRot bool
function m:Show(camPfbPath, max_fov, ui_operation_graphic, uibaseDepth, isCanUpDown, isCanScale, isCanRot) end
function m:Hide() end
---@param new_depth int
function m:OnUIControllerDepthChange(new_depth) end
UI3DModule = m
return m