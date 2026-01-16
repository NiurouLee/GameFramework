---@class UILayerManagerHelper : object
local m = {}
function m:Dispose() end
---@param depth int
---@param flag bool
function m:ShowLayer(depth, flag) end
---@param depth int
---@return bool
function m:IsLayerShow(depth) end
---@param view UIView
---@param uiName string
function m:SetInVisibleParent(view, uiName) end
---@param view UIView
---@param uiName string
function m:SetMessageBoxParent(view, uiName) end
---@param view UIView
---@param uiName string
function m:SetGuideMessageBoxParent(view, uiName) end
---@param view UIView
---@param uiName string
function m:SetTopParent(view, uiName) end
---@param view UIView
---@param uiName string
function m:SetHighParent(view, uiName) end
---@param view UIView
---@param ui_name string
---@param ui_mask_type MaskType
---@param depth int
function m:ChangeUIDepth(view, ui_name, ui_mask_type, depth) end
---@param depth int
function m:SetTopDepth(depth) end
---@param depth int
---@return UnityEngine.Camera
function m:GetCameraByDepth(depth) end
---@return UnityEngine.Camera
function m:GetMessageBoxCamera() end
---@param depth int
function m:RefreshBlurMask(depth) end
---@param depth int
---@param value bool
function m:SetDepthRaycast(depth, value) end
UILayerManagerHelper = m
return m