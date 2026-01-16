---@class UIActivityBattlePassBoard:UICustomWidget
_class("UIActivityBattlePassBoard", UICustomWidget)
UIActivityBattlePassBoard = UIActivityBattlePassBoard

--region component help
--- @return BuyGiftComponent
function UIActivityBattlePassBoard:_GetBuyGiftComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponent(cmptId)
end

--- @return BuyGiftComponentInfo
function UIActivityBattlePassBoard:_GetBuyGiftComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponentInfo(cmptId)
end
--endregion

function UIActivityBattlePassBoard:_GetComponents()
    ---@type UILocalizationText
    self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")

    ---@type UIDynamicScrollView
    self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

    ---@type UILocalizationText
    self._buyBtn = self:GetUIComponent("Button", "buyBtn")
    self._txtBuyBtn = self:GetUIComponent("UILocalizationText", "txtBuyBtn")
end

function UIActivityBattlePassBoard:OnShow()
    self._isOpen = true
    self:_GetComponents()
end

function UIActivityBattlePassBoard:OnHide()
    self._isOpen = false
end

---@param type CampaignGiftType
function UIActivityBattlePassBoard:SetData(campaign, type, price, callback)
    self._campaign = campaign
    -- type 类型
    -- 0 = elite = UIActivityBattlePassBoard
    -- 1 = deluxe = UIActivityBattlePassBoard_Deluxe
    -- 2 = deluxe = UIActivityBattlePassBoard_Deluxe
    ---@type CampaignGiftType
    self._type = type
    self._price = price
    self._callback = callback

    self:_SetTitle()
    self:_SetDesc()
    self:_SetDiscount()
    self:_SetBuyBtn()

    self._isFirst = true
    if self._isFirst then
        self:_FillUIData()
        self:_InitDynamicList()

        self._isFirst = false
    else
        self:_Refresh()
    end
end

function UIActivityBattlePassBoard:_SetTitle()
    local type2id = {
        [CampaignGiftType.ECGT_ADVANCED] = "str_activity_battlepass_elite",
        [CampaignGiftType.ECGT_LUXURY] = "str_activity_battlepass_deluxe",
        [CampaignGiftType.ECGT_ADDITIONALBUY] = "str_activity_battlepass_deluxe"
    }
    self._txtTitle:SetText(StringTable.Get(type2id[self._type]))
end

function UIActivityBattlePassBoard:_SetDesc()
    if self._type == CampaignGiftType.ECGT_LUXURY or self._type == CampaignGiftType.ECGT_ADDITIONALBUY then
        local id = "str_activity_battlepass_buy_deluxe_desc"

        ---@type UILocalizationText
        self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
        self._txtDesc:SetText(StringTable.Get(id))
    end
end

function UIActivityBattlePassBoard:_SetDiscount()
    if self._type == CampaignGiftType.ECGT_LUXURY then
        --- @type BuyGiftComponent
        local component = self:_GetBuyGiftComponent()

        local obj = self:GetGameObject("discount")

        local giftId = component:GetFirstGiftIDByType(self._type)
        local gift = component:GetGiftPriceForShowById(giftId)
        local id = gift and gift.ShowPrice or ""
        if not string.isnullorempty(id) then
            ---@type UILocalizationText
            self._txtTitleDiscount = self:GetUIComponent("UILocalizationText", "txtTitleDiscount")
            self._txtTitleDiscount:SetText(StringTable.Get(id))
            obj:SetActive(true)
        else
            obj:SetActive(false)
        end
    elseif self._type == CampaignGiftType.ECGT_ADDITIONALBUY then
        local obj = self:GetGameObject("discount")
        obj:SetActive(false)
    end
end

function UIActivityBattlePassBoard:_SetBuyBtn()
    ---@type BuyGiftComponentInfo
    local componentInfo = self:_GetBuyGiftComponentInfo()

    local type2buy = {
        [CampaignGiftType.ECGT_ADVANCED] = componentInfo.m_buy_state ~= BuyGiftStateType.EBGST_INIT,
        [CampaignGiftType.ECGT_LUXURY] = componentInfo.m_buy_state == BuyGiftStateType.EBGST_LUXURY,
        [CampaignGiftType.ECGT_ADDITIONALBUY] = componentInfo.m_buy_state == BuyGiftStateType.EBGST_LUXURY
    }
    local allreadyBuy = type2buy[self._type]
    if allreadyBuy then
        self._txtBuyBtn:SetText(StringTable.Get("str_activity_battlepass_buy_deluxe_allready_buy_btn"))
        self._buyBtn.interactable = false
    else
        self._txtBuyBtn:SetText(tostring(self._price))
    end
end

function UIActivityBattlePassBoard:_Refresh()
    if self._isOpen then
        self:_FillUIData()

        self:_RefreshList(self._dynamicListInfo, self._dynamicList)
    end
end

function UIActivityBattlePassBoard:_RefreshList(info, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(self._dynamicListSize)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityBattlePassBoard:_FillUIData()
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()

    local giftId = component:GetFirstGiftIDByType(self._type)
    self._dynamicListInfo = component:GetGiftCfgShowAwardById(giftId)

    self._itemCountPerRow = 1
    self._dynamicListSize = math.floor((table.count(self._dynamicListInfo) - 1) / self._itemCountPerRow + 1)
end

--region DynamicList
function UIActivityBattlePassBoard:_InitDynamicList()
    self._dynamicList:InitListView(
        self._dynamicListSize,
        function(scrollView, index)
            return self:_SpawnListItem(scrollView, index)
        end
    )
end

function UIActivityBattlePassBoard:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIActivityBattlePassIconText", self._itemCountPerRow)
    end
    ---@type UIActivityBattlePassIconText[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        self:_SetListItemData(listItem, itemIndex)
    end
    return item
end

---@param listItem UIActivityBattlePassIconText
function UIActivityBattlePassBoard:_SetListItemData(listItem, index)
    local info = self._dynamicListInfo[index]
    listItem:GetGameObject():SetActive(true)
    if (info ~= nil) then
        listItem:SetData(index, info.ShowIcon, info.ShowDesc)
    end
end
--endregion

--region Event Callback
function UIActivityBattlePassBoard:BuyBtnOnClick(go)
    if self._buyBtn.interactable then
        Log.info("UIActivityBattlePassBoard:BuyBtnOnClick")
        if self._callback then
            self._callback(self._type)
        end
    end
end
--endregion
