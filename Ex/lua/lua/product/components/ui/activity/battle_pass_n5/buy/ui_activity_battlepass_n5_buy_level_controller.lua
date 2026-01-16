--- @class UIActivityBattlePassN5BuyLevelController:UIController
_class("UIActivityBattlePassN5BuyLevelController", UIController)
UIActivityBattlePassN5BuyLevelController = UIActivityBattlePassN5BuyLevelController

--region component help
--- @return LVRewardComponent
function UIActivityBattlePassN5BuyLevelController:_GetLVRewardComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponent(cmptId)
end

--- @return LVRewardComponentInfo
function UIActivityBattlePassN5BuyLevelController:_GetLVRewardComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD
    return self._campaign:GetComponentInfo(cmptId)
end

--- @return BuyGiftComponent
function UIActivityBattlePassN5BuyLevelController:_GetBuyGiftComponent()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponent(cmptId)
end

--- @return BuyGiftComponentInfo
function UIActivityBattlePassN5BuyLevelController:_GetBuyGiftComponentInfo()
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    return self._campaign:GetComponentInfo(cmptId)
end

--endregion

function UIActivityBattlePassN5BuyLevelController:_GetComponents()
    -- local backBtns = self:GetUIComponent("UISelectObjectPath", "backBtns")
    -- ---@type UICommonTopButton
    -- self._backBtns = backBtns:SpawnObject("UICommonTopButton")
    -- self._backBtns:SetData(
    --     function()
    --         self:CloseDialog()
    --     end
    -- )

    ---@type UILocalizationText
    self._txtTitle = self:GetUIComponent("UILocalizationText", "txtTitle")
    ---@type UILocalizationText
    self._txtTitle2 = self:GetUIComponent("UILocalizationText", "txtTitle2")

    self._rollingText = self:GetUIComponent("RollingText", "txtTitle2")

    ---@type UILocalizationText
    self._txtNum = self:GetUIComponent("UILocalizationText", "txtNum")
    ---@type UnityEngine.UI.Image
    self._icon = self:GetUIComponent("Image", "imgBuyBtn")

    self._txtPrice = {
        self:GetUIComponent("UILocalizationText", "txtPrice_Normal"),
        self:GetUIComponent("UILocalizationText", "txtPrice_Press")
    }

    self._pressObj = {
        { self:GetGameObject("state_BuyBtnNormal") },
        { self:GetGameObject("state_BuyBtnPress") }
    }
end

--- @param TT 协程函数标识
--- @param res AsyncRequestRes 异步请求结果
function UIActivityBattlePassN5BuyLevelController:LoadDataOnEnter(TT, res, uiParams)
    ---@type CampaignModule
    local campaignModule = GameGlobal.GetModule(CampaignModule)
    -- 获取活动 以及本窗口需要的组件
    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    self._campaign:LoadCampaignInfo(
        TT,
        res,
        ECampaignType.CAMPAIGN_TYPE_BATTLEPASS,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_LV_REWARD,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_1,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_2,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_QUEST_3,
        ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT
    )
    -- 错误处理
    if res and not res:GetSucc() then
        campaignModule:CheckErrorCode(res.m_result, self._campaign._id, nil, nil)
    end
end

function UIActivityBattlePassN5BuyLevelController:OnShow(uiParams)
    self:_AttachEvents()
    self:_SetPressEvent()

    self._isOpen = true
    if uiParams then
        self.callback = uiParams[1]
    end

    self:_GetComponents()

    -- 货币类型
    self.saleType = RoleAssetID.RoleAssetGlow
    -- 购买的数量
    self._giftNum = 1

    self:_Refresh()
end

function UIActivityBattlePassN5BuyLevelController:OnHide()
    self:_DetachEvents()
    self._isOpen = false
end

function UIActivityBattlePassN5BuyLevelController:_Refresh()
    if self._isOpen then
        self:_SetTitle()
        self:_SetBuyNum()
        self:_SetBuyBtnIcon()
        self:_SetBuyBtnPrice()

        self:_SetDynamicList()
    end
end

function UIActivityBattlePassN5BuyLevelController:_SetTitle()
    --- @type BuyLVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()
    local _max = componentInfo.m_max_level - componentInfo.m_current_level

    local content = StringTable.Get("str_activity_battlepass_tab_reward_buy_level_btn")
    local colorStr = "FFFFFF"
    local formatStr = "<color=#%s>%s</color>"
    local showStr = string.format(formatStr, colorStr, content)
    self._txtTitle:SetText(showStr)

    self._txtTitle2:SetText(
        StringTable.Get(
            "str_activity_battlepass_n5_buy_level_desc",
            componentInfo.m_current_level,
            componentInfo.m_current_level + self._giftNum
        )
    )
    self._rollingText:RefreshText(nil)
end

function UIActivityBattlePassN5BuyLevelController:_SetBuyNum()
    self._txtNum:SetText(tostring(self._giftNum))
end

function UIActivityBattlePassN5BuyLevelController:_SetBuyBtnIcon()
    self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self._icon.sprite = self.uiCommonAtlas:GetSprite(ClientShop.GetCurrencyImageName(self.saleType))
end

function UIActivityBattlePassN5BuyLevelController:_SetBuyBtnPrice()
    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()

    local giftType = CampaignGiftType.ECGT_BPLEVEL
    local giftId = component:GetFirstGiftIDByType(giftType)
    local gift = Cfg.cfg_shop_common_goods[giftId]
    self._price = gift.NewPrice * self._giftNum

    for _, v in pairs(self._txtPrice) do
        v:SetText(tostring(self._price))
    end
end

function UIActivityBattlePassN5BuyLevelController:_UpdateBuyNum(n)
    --- @type BuyLVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    local _max = componentInfo.m_max_level - componentInfo.m_current_level
    local _min = 1
    local next = self._giftNum + n

    next = math.max(next, _min)
    next = math.min(next, _max)
    self._giftNum = next

    self:_Refresh()
end

--region DynamicList
function UIActivityBattlePassN5BuyLevelController:_SetDynamicListData()
    --- @type BuyLVRewardComponent
    local component = self:_GetLVRewardComponent()
    --- @type BuyLVRewardComponentInfo
    local componentInfo = self:_GetLVRewardComponentInfo()

    local rewards = nil
    local curLv = componentInfo.m_current_level
    if componentInfo.m_unlock_advanced_reward then
        rewards = component:GetSortAdvancedRewards(curLv + 1, curLv + self._giftNum)
    else
        rewards = component:GetSortNormalRewards(curLv + 1, curLv + self._giftNum)
    end

    self._dynamicListInfo = {}
    for i = 1, #rewards do
        table.insert(self._dynamicListInfo, rewards[i])
    end

    self._dynamicListSize = table.count(self._dynamicListInfo)
    self._itemCountPerRow = 7
    self._dynamicListRowSize = math.floor((self._dynamicListSize - 1) / self._itemCountPerRow + 1)
end

function UIActivityBattlePassN5BuyLevelController:_SetDynamicList()
    self:_SetDynamicListData()

    if not self._isDynamicInited then
        self._isDynamicInited = true

        ---@type UIDynamicScrollView
        self._dynamicList = self:GetUIComponent("UIDynamicScrollView", "dynamicList")

        self._dynamicList:InitListView(
            self._dynamicListRowSize,
            function(scrollView, index)
                return self:_SpawnListItem(scrollView, index)
            end
        )
    else
        self:_RefreshList(self._dynamicListRowSize, self._dynamicList)
    end
end

function UIActivityBattlePassN5BuyLevelController:_RefreshList(count, list)
    local contentPos = list.ScrollRect.content.localPosition
    list:SetListItemCount(count)
    list:RefreshAllShownItem()
    list:MovePanelToItemIndex(0, 0)
    list.ScrollRect.content.localPosition = contentPos
end

function UIActivityBattlePassN5BuyLevelController:_SpawnListItem(scrollView, index)
    if index < 0 then
        return nil
    end
    local item = scrollView:NewListViewItem("RowItem")
    local rowPool = self:GetUIComponentDynamic("UISelectObjectPath", item.gameObject)
    if item.IsInitHandlerCalled == false then
        item.IsInitHandlerCalled = true
        rowPool:SpawnObjects("UIActivityBattlePassN5ItemIcon", self._itemCountPerRow)
    end
    ---@type UIActivityBattlePassN5ItemIcon[]
    local rowList = rowPool:GetAllSpawnList()
    for i = 1, self._itemCountPerRow do
        local listItem = rowList[i]
        local itemIndex = index * self._itemCountPerRow + i
        if itemIndex > self._dynamicListSize then
            listItem:GetGameObject():SetActive(false)
        else
            listItem:GetGameObject():SetActive(true)
            self:_SetListItemData(listItem, itemIndex)
        end
    end
    return item
end

---@param listItem UIActivityBattlePassN5ItemIcon
function UIActivityBattlePassN5BuyLevelController:_SetListItemData(listItem, index)
    local info = self._dynamicListInfo[index]

    if info ~= nil then
        listItem:SetData(
            i,
            info,
            function(matid, pos)
                UIWidgetHelper.SetAwardItemTips(self, "itemInfoPool", matid, pos)
            end,
            UIItemScale.Level2
        )
    end
end

--endregion

--region PrepareToBuy
function UIActivityBattlePassN5BuyLevelController:_ShowBuyConfirm(price, giftNum)
    PopupManager.Alert(
        "UICommonMessageBox",
        PopupPriority.Normal,
        PopupMsgBoxType.OkCancel,
        "",
        StringTable.Get("str_activity_battlepass_pay_gb_2_lv_gift", price, giftNum), -- 是否消耗{1}光珀，购买{2}级通行证等级
        function(param)
            if not ClientShop.CheckBuy(self.saleType, price) then
                return
            end
            self:_Start_HandleApplyBuyGiftReq()
        end,
        nil,
        nil,
        nil
    )
end

--endregion

--region req
function UIActivityBattlePassN5BuyLevelController:_Start_HandleApplyBuyGiftReq()
    GameGlobal.GetModule(PetModule):GetAllPetsSnapshoot()

    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()
    local giftId = component:GetFirstGiftIDByType(CampaignGiftType.ECGT_BPLEVEL)

    component:BuyGift(giftId, self._giftNum)
end

--endregion

--region Event Callback
function UIActivityBattlePassN5BuyLevelController:Dec10BtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    Log.info("UIActivityBattlePassN5BuyLevelController:Dec10BtnOnClick")
    self:_UpdateBuyNum(-10)
end

function UIActivityBattlePassN5BuyLevelController:DecBtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    Log.info("UIActivityBattlePassN5BuyLevelController:DecBtnBtnOnClick")
    self:_UpdateBuyNum(-1)
end

function UIActivityBattlePassN5BuyLevelController:IncBtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundAddUp)
    Log.info("UIActivityBattlePassN5BuyLevelController:IncBtnOnClick")
    self:_UpdateBuyNum(1)
end

function UIActivityBattlePassN5BuyLevelController:Inc10BtnOnClick(go)
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundAddUp)
    Log.info("UIActivityBattlePassN5BuyLevelController:Inc10BtnOnClick")
    self:_UpdateBuyNum(10)
end

function UIActivityBattlePassN5BuyLevelController:BuyBtnOnClick(go)
    Log.info("UIActivityBattlePassN5BuyLevelController:BuyBtnOnClick")
    self:_ShowBuyConfirm(self._price, self._giftNum)
end

function UIActivityBattlePassN5BuyLevelController:CancelBtnOnClick(go)
    Log.info("UIActivityBattlePassN5BuyLevelController:CancelBtnOnClick")
    self:CloseDialog()
end

--endregion

--region AttachEvent
function UIActivityBattlePassN5BuyLevelController:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.ActivityNormalBuyResult, self._OnNormalBuyResult)
end

function UIActivityBattlePassN5BuyLevelController:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.ActivityNormalBuyResult, self._OnNormalBuyResult)
end

function UIActivityBattlePassN5BuyLevelController:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

-- 活动 普通购买 的回调
function UIActivityBattlePassN5BuyLevelController:_OnNormalBuyResult(gift_id, res)
    if (self.view == nil) then
        return
    end

    --- @type BuyGiftComponent
    local component = self:_GetBuyGiftComponent()
    local giftId = component:GetFirstGiftIDByType(CampaignGiftType.ECGT_BPLEVEL)
    if giftId ~= gift_id then
        return
    end

    if res:GetSucc() then
        if self.callback then
            self.callback()
        end
        self:CloseDialog()
    else
        ---@type CampaignModule
        local campaignModule = GameGlobal.GetModule(CampaignModule)
        campaignModule:CheckErrorCode(
            res.m_result,
            self._campaign._id,
            function()
                self:_Refresh()
            end,
            function()
                self:SwitchState(UIStateType.UIMain)
            end
        )
    end
end

--endregion

function UIActivityBattlePassN5BuyLevelController:_SetPressEvent()
    local obj = self:GetGameObject("BuyBtn")

    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(obj),
        UIEvent.Press,
        function(go)
            UIWidgetHelper.SetObjGroupShow(self._pressObj, 2)
        end
    )
    self:AddUICustomEventListener(
        UICustomUIEventListener.Get(obj),
        UIEvent.Release,
        function(go)
            UIWidgetHelper.SetObjGroupShow(self._pressObj, 1)
        end
    )
end
