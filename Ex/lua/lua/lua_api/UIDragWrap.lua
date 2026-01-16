---@class UIDrag : UnityEngine.MonoBehaviour
---@field ScrollViewRect UnityEngine.UI.ScrollRect
---@field DynamicScrollView UIDynamicScrollView
---@field H3dScrollView H3DScrollView
---@field ScalableSR ScalableScrollRect
---@field EnableClickWhenDrag bool
---@field mScrollViewRect UnityEngine.UI.ScrollRect
---@field mDynamicScrollView UIDynamicScrollView
---@field mH3DScrollView H3DScrollView
---@field mBeginDrag UnityEngine.EventSystems.IBeginDragHandler
---@field mEndDrag UnityEngine.EventSystems.IEndDragHandler
---@field mDrag UnityEngine.EventSystems.IDragHandler
local m = {}
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnBeginDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnEndDrag(eventData) end
UIDrag = m
return m