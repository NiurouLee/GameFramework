---@class UIActivityBattlePassN5Board:UICustomWidget
_class("UIActivityBattlePassN5Board", UICustomWidget)
UIActivityBattlePassN5Board = UIActivityBattlePassN5Board

--region component help
--- @return BuyGiftComponent
function UIActivityBattlePassN5Board:_GetBuyGiftComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponent(cmptId)
end

--- @return BuyGiftComponentInfo
function UIActivityBattlePassN5Board:_GetBuyGiftComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponentInfo(cmptId)
end
--endregion

function UIActivityBattlePassN5Board:_GetComponents()
    ---@type UILocalizationText
    self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")

    ---@type UIDynamicScrollView
    self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

    ---@type UILocalizationText
    self._buyBtn = self:GetUIComponent("Button", "buyBtn")
    self._txtBuyBtn = self:GetUIComponent("UILocalizationText", "txtBuyBtn")
end

function UIActivityBattlePassN5Board:OnShow()
    self._isOpen = true
    self:_GetComponents()
end

function UIActivityBattlePassN5Board:OnHide()
    self._isOpen = false
end

---@param type CampaignGiftType
function UIActivityBattlePassN5Board:SetData(campaign, type, price, callback)
    self._campaign = campaign
    -- type 类型
    -- 0 = elite = UIActivityBattlePassN5Board
    -- 1 = deluxe = UIActivityBattlePassN5Board_Deluxe
    -- 2 = deluxe = UIActivityBattlePassN5Board_Deluxe
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

    self:_PlayAnimIn()
end

function UIActivityBattlePassN5Board:RefreshBuyStatus()
    --- @type BuyGiftComponentInfo
    local componentInfo = self:_GetBuyGiftComponentInfo()
    local buyState = componentInfo.m_buy_state

    if self._type == CampaignGiftType.ECGT_ADVANCED then --精英版礼包
        local state2show = {
            [BuyGiftStateType.EBGST_INIT] = 0, -- 没有购买
            [BuyGiftStateType.EBGST_ADVANCED] = 1, -- 已购买精英版，显示”已购买“
            [BuyGiftStateType.EBGST_LUXURY] = 2 -- 已购买豪华版，显示”您已购买豪华版“
        }
        local flag = state2show[buyState]
        local isShow = (flag ~= 0)
        local showType = (flag == 1) and true or false
        self:ShowBuyTips(isShow, showType)
    else
        local state2show = {
            [BuyGiftStateType.EBGST_INIT] = 0, -- 没有购买
            [BuyGiftStateType.EBGST_ADVANCED] = 0, -- 已购买精英版，但是右侧不显示”已购买“
            [BuyGiftStateType.EBGST_LUXURY] = 1 -- 已购买豪华版，显示”已购买“
        }
        local flag = state2show[buyState]
        local isShow = (flag == 1)
        local showType = (flag == 1) and true or false
        self:ShowBuyTips(isShow, showType)
    end
end

function UIActivityBattlePassN5Board:ShowBuyTips(isShow, showNormal)
    local hasBuy = self:GetGameObject("HasBuy")
    if hasBuy then
        hasBuy:SetActive(isShow)
    end

    if not isShow then
        return
    end

    local normal = self:GetGameObject("Normal")
    if normal then
        normal:SetActive(showNormal)
    end
    local deluxe = self:GetGameObject("Deluxe")
    if deluxe then
        deluxe:SetActive(not showNormal)
    end
end

function UIActivityBattlePassN5Board:_SetTitle()
    local type2id = {
        [CampaignGiftType.ECGT_ADVANCED] = "str_activity_battlepass_elite",
        [CampaignGiftType.ECGT_LUXURY] = "str_activity_battlepass_deluxe",
        [CampaignGiftType.ECGT_ADDITIONALBUY] = "str_activity_battlepass_deluxe"
    }
    self._txtTitle:SetText(StringTable.Get(type2id[self._type]))
end

function UIActivityBattlePassN5Board:_SetDesc()
    if self._type == CampaignGiftType.ECGT_LUXURY or self._type == CampaignGiftType.ECGT_ADDITIONALBUY then
        local id = "str_activity_battlepass_buy_deluxe_desc_n5"

        ---@type UILocalizationText
        self._txtDesc = self:GetUIComponent("UILocalizationText", "txtDesc")
        self._txtDesc:SetText(StringTable.Get(id))
    end
end

function UIActivityBattlePassN5Board:_SetDiscount()
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

function UIActivityBattlePassN5Board:_SetBuyBtn()
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

function UIActivityBattlePassN5Board:_Refresh()
    if self._isOpen then
        self:_FillUIData()

        self:_RefreshList(self._dynamicListInfo, self._dynamicList)
    end
end

function UIActivityBattlePassN5Board:_RefreshList(info, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(self._dynamicListSize)
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityBattlePassN5Board:_FillUIData()
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()

    local giftId = component:GetFirstGiftIDByType(self._type)
    self._dynamicListInfo = component:GetGiftCfgShowAwardById(giftId)

    self._itemCountPerRow = 2
    self._dynamicListSize = math.floor((table.count(self._dynamicListInfo) - 1) / self._itemCountPerRow + 1)

    if self._type == CampaignGiftType.ECGT_ADVANCED then
        if self._dynamicListInfo and #self._dynamicListInfo > 0 then
            local cfg = self._dynamicListInfo[1]
            local iconLoader = self:GetUIComponent("RawImageLoader", "Icon")
            if iconLoader then
                iconLoader:LoadImage(cfg.ShowIcon) -- 使用第一个奖励的图标
            end

            -- 文字配置多期
            ---@type UILocalizationText
            local iconTitle1 = self:GetUIComponent("UILocalizationText", "iconTitle1")
            local strId =
                UIActivityBattlePassHelper.GetStrIdInCampaign(self._campaign, "str_activity_battlepass_n5_cg_name_1")
            iconTitle1:SetText(StringTable.Get(strId))
        else
            local iconGo = self:GetGameObject("Icon")
            iconGo:SetActive(false)
        end
    end

    -- 第一个奖励特殊显示
    self._dynamicListInfo = self:_RemoveFirstData(self._dynamicListInfo)
    self._dynamicListSize = math.floor((table.count(self._dynamicListInfo) - 1) / self._itemCountPerRow + 1)
end

function UIActivityBattlePassN5Board:_RemoveFirstData(tb)
    local newTb = {}
    for i, v in ipairs(tb) do
        if i ~= 1 then
            table.insert(newTb, v)
        end
    end
    return newTb
end

--region DynamicList
function UIActivityBattlePassN5Board:_InitDynamicList()
    self._dynamicList:InitListView(
        self._dynamicListSize,
        function(scrollView, index)
            return self:_SpawnListItem(scrollView, index)
        end
    )
end

function UIActivityBattlePassN5Board:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIActivityBattlePassN5IconText", self._itemCountPerRow)
    end
    ---@type UIActivityBattlePassN5IconText[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > #self._dynamicListInfo then
            listItem:GetGameObject():SetActive(false)
        else
            listItem:GetGameObject():SetActive(true)
            self:_SetListItemData(listItem, itemIndex)
        end
    end
    return item
end

---@param listItem UIActivityBattlePassN5IconText
function UIActivityBattlePassN5Board:_SetListItemData(listItem, index)
    local info = self._dynamicListInfo[index]
    listItem:GetGameObject():SetActive(true)
    if (info ~= nil) then
        listItem:SetData(index, info.ShowIcon, info.ShowDesc)
    end
end
--endregion

--region Event Callback
function UIActivityBattlePassN5Board:BuyBtnOnClick(go)
    if self._buyBtn.interactable then
        Log.info("UIActivityBattlePassN5Board:BuyBtnOnClick")
        if self._callback then
            self._callback(self._type)
        end
    end
end
--endregion

--region animation
function UIActivityBattlePassN5Board:_PlayAnimIn()
    ---@type UnityEngine.Animation
    self.anim = self:GetUIComponent("Animation", "animation")

    local type2animName = {
        [0] = "UIeff_UIActivityBattlePassN5Board_in",
        [1] = "UIeff_UIActivityBattlePassN5Board_Deluxe_in",
        [2] = "UIeff_UIActivityBattlePassN5Board_Deluxe_in"
    }
    local animName = type2animName[self._type]

    local lockName = "UIActivityBattlePassN5Board:_PlayAnimIn()" .. "type=" .. self._type
    self:Lock(lockName)
    
    self:StartTask(
        function(TT)
            YIELD(TT, 400)
            if self.view then
                self:RefreshBuyStatus()
                self.anim:Play(animName)
                YIELD(TT, 600)
            end

            self:UnLock(lockName)
        end,
        self
    )
end
--endregion
