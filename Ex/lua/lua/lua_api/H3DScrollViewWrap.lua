---@class H3DScrollView : UnityEngine.MonoBehaviour
---@field NextPageOffset float
---@field moveCountOnce int
---@field m_item_prefab_name string
---@field mOnShowItem System.Action
---@field mOnHideItem System.Action
---@field mOnCenterItem System.Action
---@field mOnEndSnapping System.Action
---@field mOnGroupChanged System.Action
---@field mOnValueChangedEvent System.Action
---@field onMovePanelToIndex System.Action
---@field mOnBeginDragAction System.Action
---@field mOnDragingAction System.Action
---@field mOnEndDragAction System.Action
---@field onItemPassSnapPos System.Action
---@field IsSnap bool
---@field _tranSnap UnityEngine.Transform
---@field maxScale float
local m = {}
---@param count int
---@param openindex int
---@param width int
---@param height int
function m:Init(count, openindex, width, height) end
function m:Dispose() end
---@param bcc bool
function m:SetCalcScale(bcc) end
---@param index int
function m:MovePanelToIndex(index) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnBeginDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnEndDrag(eventData) end
function m:CalClosestIdx() end
H3DScrollView = m
return m