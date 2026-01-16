---@class UIDynamicScrollView : UnityEngine.MonoBehaviour
---@field ArrangeType ListItemArrangeType
---@field ItemPrefabDataList table
---@field IsVertList bool
---@field ItemTotalCount int
---@field ContainerTrans UnityEngine.RectTransform
---@field ScrollRect UnityEngine.UI.ScrollRect
---@field IsDraging bool
---@field ItemSnapEnable bool
---@field SupportScrollBar bool
---@field SetContentSizeInTime bool
---@field ShownItemCount int
---@field ViewPortSize float
---@field ViewPortWidth float
---@field ViewPortHeight float
---@field CurSnapNearestItemIndex int
---@field mOnBeginDragAction System.Action
---@field mOnDragingAction System.Action
---@field mOnEndDragAction System.Action
---@field mOnSnapItemFinished System.Action
---@field mOnSnapNearestChanged System.Action
local m = {}
---@param prefabName string
---@return ItemPrefabConfData
function m:GetItemPrefabConfData(prefabName) end
---@param prefabName string
function m:OnItemPrefabChanged(prefabName) end
---@param itemTotalCount int
---@param onGetItemByIndex UIDynamicScrollView.GetItemByIndexHandler
---@param initParam UIDynamicScrollViewInitParam
function m:InitListView(itemTotalCount, onGetItemByIndex, initParam) end
function m:ResetListView() end
---@param itemCount int
---@param resetPos bool
function m:SetListItemCount(itemCount, resetPos) end
---@param itemIndex int
---@return UIDynamicScrollViewItem
function m:GetShownItemByItemIndex(itemIndex) end
---@param index int
---@return UIDynamicScrollViewItem
function m:GetShownItemByIndex(index) end
---@param index int
---@return UIDynamicScrollViewItem
function m:GetShownItemByIndexWithoutCheck(index) end
---@param item UIDynamicScrollViewItem
---@return int
function m:GetIndexInShownItemList(item) end
---@param action System.Action
---@param param object
function m:DoActionForEachShownItem(action, param) end
---@param itemPrefabName string
---@return UIDynamicScrollViewItem
function m:NewListViewItem(itemPrefabName) end
---@param itemIndex int
function m:OnItemSizeChanged(itemIndex) end
---@param itemIndex int
function m:RefreshItemByItemIndex(itemIndex) end
function m:FinishSnapImmediately() end
---@param itemIndex int
---@param offset float
function m:MovePanelToItemIndex(itemIndex, offset) end
function m:RefreshAllShownItem() end
---@param firstItemIndex int
function m:RefreshAllShownItemWithFirstIndex(firstItemIndex) end
---@param firstItemIndex int
---@param pos UnityEngine.Vector3
function m:RefreshAllShownItemWithFirstIndexAndPos(firstItemIndex, pos) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnBeginDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnEndDrag(eventData) end
---@param eventData UnityEngine.EventSystems.PointerEventData
function m:OnDrag(eventData) end
---@param item UIDynamicScrollViewItem
---@param corner ItemCornerEnum
---@return UnityEngine.Vector3
function m:GetItemCornerPosInViewPort(item, corner) end
function m:UpdateAllShownItemSnapData() end
function m:ClearSnapData() end
---@param itemIndex int
function m:SetSnapTargetItemIndex(itemIndex) end
function m:ForceSnapUpdateCheck() end
---@param distanceForRecycle0 float
---@param distanceForRecycle1 float
---@param distanceForNew0 float
---@param distanceForNew1 float
function m:UpdateListView(distanceForRecycle0, distanceForRecycle1, distanceForNew0, distanceForNew1) end
---@return bool
function m:CheckAtLast() end
---@return table
function m:GetVisibleItemIDsInScrollView() end
UIDynamicScrollView = m
return m