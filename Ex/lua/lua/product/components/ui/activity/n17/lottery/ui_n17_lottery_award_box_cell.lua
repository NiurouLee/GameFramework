---@class UIN17LotteryAwardBoxCell : UICustomWidget
_class("UIN17LotteryAwardBoxCell", UICustomWidget)
UIN17LotteryAwardBoxCell = UIN17LotteryAwardBoxCell

--
function UIN17LotteryAwardBoxCell:Constructor()
    self.listInited = false
    self.rowCellItemNum = 3
    self.rowCellCount = 0
end

--
function UIN17LotteryAwardBoxCell:OnShow(uiParams)
    self:_GetComponents()
end

--
function UIN17LotteryAwardBoxCell:_GetComponents()
    self._contentRect = self:GetUIComponent("RectTransform", "Content")
end

--
function UIN17LotteryAwardBoxCell:InitData(data, itemInfoCallBack, playJackpotAnim)
    self._data = data
    self._itemInfoCallback = itemInfoCallBack
    self._playJackpotAnim = playJackpotAnim

    self:_SetDynamicList()
end

--region DynamicList

--
function UIN17LotteryAwardBoxCell:_SetDynamicList()
    self._contentRect.anchoredPosition = Vector2(0, 0)
    self._infos = self._data.itemGroup

    if not self._dynamicListHelper then
        ---@type UIActivityDynamicListHelper
        self._dynamicListHelper =
            UIActivityDynamicListHelper:New(
            self,
            self:GetUIComponent("UIDynamicScrollView", "AwardList"),
            "UIN17LotteryAwardRowCell",
            function(listItem, itemIndex)
                local delayTime = 0
                if self._playJackpotAnim then
                    delayTime = itemIndex
                end
                listItem:InitData(self._data.itemGroup[itemIndex], self._itemInfoCallback, delayTime)
            end
        )
    end

    local itemCount = #self._infos
    local itemCountPerRow = 3
    self._dynamicListHelper:Refresh(itemCount, itemCountPerRow)
end

--endregion

-- --
-- function UIN17LotteryAwardBoxCell:_InitAwardListUi()
--     self.rowCellCount = #self._data.itemGroup
--     if self.listInited then
--         self.awardList:SetListItemCount(self.rowCellCount)
--         self.awardList:RefreshAllShownItem()
--         self.awardList:MovePanelToItemIndex(0, 0)
--         self.awardList:FinishSnapImmediately()
--         return
--     else
--         self.listInited = true
--     end
--     self.awardList:InitListView(
--         self.rowCellCount,
--         function(scrollview, index)
--             return self:_OnGetAwardRowCell(scrollview, index)
--         end
--     )
-- end

-- --
-- function UIN17LotteryAwardBoxCell:_OnGetAwardRowCell(scrollview, index)
--     local item = scrollview:NewListViewItem("RowCell")
--     local cellPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
--     if item.IsInitHandlerCalled == false then
--         item.IsInitHandlerCalled = true
--         cellPool:SpawnObjects("UIN17LotteryAwardRowCell", 1)
--     end
--     local rowList = cellPool:GetAllSpawnList()
--     local itemWidget = rowList[1]
--     ---@type UIN17LotteryAwardRowCell
--     if itemWidget then
--         local rowIndex = index + 1
--         if rowIndex > self.rowCellCount then
--             itemWidget:GetGameObject():SetActive(false)
--         else
--             local delayTime = 0
--             if self._playJackpotAnim then
--                 delayTime = rowIndex
--             end
--             itemWidget:InitData(self._data.itemGroup[rowIndex], self._itemInfoCallback, delayTime)
--         end
--     end
--     return item
-- end
