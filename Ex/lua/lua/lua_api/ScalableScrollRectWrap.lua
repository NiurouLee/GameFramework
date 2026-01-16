---@class ScalableScrollRect : UnityEngine.EventSystems.UIBehaviour
---@field horizontal bool
---@field vertical bool
---@field viewport UnityEngine.RectTransform
---@field content UnityEngine.RectTransform
---@field OnContentPosChanged System.Action
---@field onContentScaleChanged H3dDelegate.DelegateFloat
local m = {}
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnBeginDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnEndDrag(eventData) end
---@param scale float
function m:UpdateContentScale(scale) end
---@return bool
function m:IsDragging() end
---@return bool
function m:IsScaling() end
---@param scaleRange UnityEngine.Vector2
---@param damping float
function m:Init(scaleRange, damping) end
function m:GraphicUpdateComplete() end
function m:LayoutComplete() end
---@param executing UnityEngine.UI.CanvasUpdate
function m:Rebuild(executing) end
ScalableScrollRect = m
return m