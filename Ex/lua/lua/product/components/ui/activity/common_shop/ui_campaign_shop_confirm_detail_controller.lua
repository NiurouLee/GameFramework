---@class UICampaignShopConfirmDetailController : UIController
_class("UICampaignShopConfirmDetailController", UIController)
UICampaignShopConfirmDetailController = UICampaignShopConfirmDetailController
local MAX_COUNT = 99
function UICampaignShopConfirmDetailController:Constructor()
end
function UICampaignShopConfirmDetailController:OnShow(uiParams)
    self:InitWidget(uiParams)
end
function UICampaignShopConfirmDetailController:InitWidget(uiParams)
    --generated--
    ---@type DCampaignShopItemBase
    self.goodsData = uiParams[1]
    ---@type ExchangeItemComponentInfo
    local cmptInfo = self.goodsData.exchangeCmpt:GetComponentInfo()
    self._campaignId = cmptInfo.m_campaign_id
    self._componentId = cmptInfo.m_component_id
    ---@type ExchangeItemComponent
    self._componentFullId =
        self.goodsData.exchangeCmpt:GetComponetCfgId(cmptInfo.m_campaign_id, cmptInfo.m_component_id)

    self.subTabType = uiParams[2]
    self.isPet = self.goodsData:IsPet()
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.nameTrans = self:GetUIComponent("Transform", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    self.descRect = self:GetUIComponent("RectTransform", "desc")
    self.descScroll = self:GetUIComponent("ScrollRect", "ContentPanel")
    self.btnStarGO = self:GetGameObject("btnstar")
    self.btnGo = self:GetGameObject("btnGo")
    self.countGroupGO = self:GetGameObject("countgroup")
    self.countGroupRect = self:GetUIComponent("RectTransform", "countgroup")
    self._currentCount = self:GetUIComponent("UILocalizationText", "itemCount")
    self.moneyIconLoader = self:GetUIComponent("RawImageLoader", "moneyicon")
    self.priceTxt = self:GetUIComponent("UILocalizationText", "price")
    self.countTxt = self:GetUIComponent("UILocalizationText", "count")
    self.countFollowTxt = self:GetUIComponent("UILocalizationText", "countfollow")

    self.remainTxt = self:GetUIComponent("UILocalizationText", "remain")
    self.remainGO = self:GetGameObject("remaintxt")
    local btnBuyGO = self:GetGameObject("btnbuy")
    local txt = self:GetUIComponent("UILocalizationText", "txt")
    local etl = UICustomUIEventListener.Get(btnBuyGO)
    self:AddUICustomEventListener(
        etl,
        UIEvent.Press,
        function(go)
            txt.color = Color.white
            self.priceTxt.color = Color.white
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Unhovered,
        function(go)
            txt.color = Color.black
            self:SetTextColor()
        end
    )
    self:AddUICustomEventListener(
        etl,
        UIEvent.Release,
        function(go)
            txt.color = Color.black
            self:SetTextColor()
        end
    )
    --self:InitPlayerSpine()
    self:Refresh()
    --generated end--
end

function UICampaignShopConfirmDetailController:SetTextColor()
    local ownMoney = ClientCampaignShop.GetMoney(self.saleType)
    if ownMoney >= self.price then
        self.priceTxt.color = Color.black
    else
        self.priceTxt.color = Color.red
    end
end

-- body
function UICampaignShopConfirmDetailController:Refresh()
    if not self.goodsData then
        return
    end
    local cfgItem = Cfg.cfg_item[self.goodsData:GetItemId()]
    if not cfgItem then
        return
    end
    self.count = 1
    self.singlePrice = self.goodsData:GetSalePrice()
    local itemId = cfgItem.ID
    local icon = cfgItem.Icon
    local quality = cfgItem.Color
    local count = self.goodsData:GetItemCount()
    local text1 = count <= 1 and "" or StringTable.Get("str_shop_good_count") .. count
    self.uiItem:SetData({icon = icon, quality = quality, text1 = text1, itemId = itemId})
    self.nameTxt:SetText("「" .. StringTable.Get(cfgItem.Name) .. "」")

    local itemCount = self:GetModule(ItemModule):GetItemCount(itemId)
    self._currentCount:SetText(StringTable.Get("str_shop_current_item_count", itemCount))
    
    self.descTxt:SetText(StringTable.Get(cfgItem.Intro))
    self.saleType = self.goodsData:GetCostItemId()
    self.moneyIconLoader:LoadImage(ClientCampaignShop.GetCurrencyImageName(self.saleType))
    if self.isPet then
        --self.nameTrans.localPosition = Vector3(95.6, -72)
        self.btnGo:SetActive(true)
    else
        --self.nameTrans.localPosition = Vector3(95.6, -117)
        self.btnGo:SetActive(false)
    end
    self.remainCount = self.goodsData:GetRemainCount()
    self.countGroupGO:SetActive(true)
    if self.goodsData:IsUnLimit() then
        self.remainGO:SetActive(false)
        self.countGroupRect.anchoredPosition = Vector2(0, 151)
    else
        self.remainGO:SetActive(true)
        self.remainTxt:SetText(self.remainCount)
        self.countGroupRect.anchoredPosition = Vector2(0, 169)
    end
    self:SetCountPriceTxt()

    self:DoAnimation()
    self:SetScroll()
end
function UICampaignShopConfirmDetailController:SetScroll()
    local perferredH = self.descTxt.preferredHeight
    if perferredH < 135 then
        self.descScroll.vertical = false
    else
        self.descScroll.vertical = true
    end
end
function UICampaignShopConfirmDetailController:DoAnimation()
    self._cg = self:GetUIComponent("CanvasGroup", "UICanvas")
    self._panel = self:GetUIComponent("RectTransform", "panel")
    self._infoTrans = self:GetUIComponent("Transform", "info")
    self._cg.alpha = 0

    self:StartTask(
        function(TT)
            YIELD(TT)
            YIELD(TT)
            local descHeight = self.descRect.sizeDelta.y
            if descHeight < 130 then
                descHeight = 130
            elseif descHeight < 178 then
                descHeight = 178
            end
            if descHeight > 82 and descHeight < 130 then
                self._panel.sizeDelta = Vector2(830, 642)
            elseif descHeight >= 130 and descHeight < 178 then
                self._panel.sizeDelta = Vector2(830, 680)
            elseif descHeight >= 178 then
                self._panel.sizeDelta = Vector2(830, 722)
            end

            self._cg:DOFade(1, 0.3)
            self._panel.localScale = Vector3(0.5, 0.5, 0.5)
            local y = self._infoTrans.localPosition.y
            self._panel:DOScale(Vector3(1, 1, 1), 0.3):OnComplete(
                function()
                end
            )
            self._infoTrans:DOLocalMoveY(y + 3, 0.2):OnComplete(
                function()
                    self._infoTrans:DOLocalMoveY(y - 3, 0.2)
                end
            )
        end,
        self
    )
end
function UICampaignShopConfirmDetailController:OnHide()
    if self._spine then
        self._spine:DestroyCurrentSpine()
        self._spine = nil
    end
end

function UICampaignShopConfirmDetailController:BtnstarOnClick(go)
    self:ShowDialog("UIShopPetDetailController", self.goodsData:GetItemId())
end
function UICampaignShopConfirmDetailController:BtnbuyOnClick(go)
    if not ClientCampaignShop.CheckBuy(self.saleType, self.price) then
        if self.saleType == RoleAssetID.RoleAssetGlow then
            self:CloseDialog()
        end
        --MSG25592	【TAPD_80994942】【必现】（测试_朱文科）伊芙醒山活动，公路商店，兑换商品，扳手螺帽徽章不足，点击兑换商品，没有提示，建议增加提示，附截图	4	新缺陷	李学森, 1958	06/24/2021
        local tips = StringTable.Get("str_pay_item_not_enough")
        ToastManager.ShowToast(tips)
        return
    end
    ---@type ExchangeItemComponent
    local exchangeCmpt = self.goodsData.exchangeCmpt
    if exchangeCmpt then
        self:StartTask(
            function(TT)
                self:Lock("UICampaignShopConfirmDetailController:btnbuyOnClick")
                local res = AsyncRequestRes:New()
                local rewards = exchangeCmpt:HandleExchangeItem(TT, res, self.goodsData:GetGoodsId(), self.count)
                self:UnLock("UICampaignShopConfirmDetailController:btnbuyOnClick")
                if res:GetSucc() then
                    if rewards and #rewards > 0 then
                        local roleAsset = rewards[1]
                        local assetList = rewards
                        if self:GetModule(PetModule):IsPetID(roleAsset.assetid) then
                            self:ShowDialog(
                                "UIPetObtain",
                                assetList,
                                function()
                                    GameGlobal.UIStateManager():CloseDialog("UIPetObtain")
                                    self:ShowDialog(
                                        "UIGetItemController",
                                        assetList,
                                        function()
                                            GameGlobal.EventDispatcher():Dispatch(
                                                GameEventType.ActivityShopBuySuccess,
                                                self.goodsData:GetGoodsId()
                                            )
                                        end
                                    )
                                    self:CloseDialog()
                                end
                            )
                        else
                            self:ShowDialog(
                                "UIGetItemController",
                                assetList,
                                function()
                                    GameGlobal.EventDispatcher():Dispatch(
                                        GameEventType.ActivityShopBuySuccess,
                                        self.goodsData:GetGoodsId()
                                    )
                                end
                            )
                            self:CloseDialog()
                        end
                    else
                        self:CloseDialog()
                    end
                else
                    if res:GetResult() == CampaignErrorType.E_CAMPAIGN_ERROR_TYPE_COMPONENT_CLOSE then
                        GameGlobal.EventDispatcher():Dispatch(
                            GameEventType.ActivityComponentCloseEvent,
                            self._componentFullId
                        )
                    end
                    ---@type CampaignModule
                    local campaignModule = GameGlobal.GetModule(CampaignModule)
                    campaignModule:CheckErrorCode(
                        res:GetResult(),
                        self._campaignId,
                        function()
                            GameGlobal.EventDispatcher():Dispatch(
                                GameEventType.ActivityShopNeedRefresh,
                                self._campaignId
                            )
                        end,
                        nil
                    )
                    self:CloseDialog()
                end
            end,
            self
        )
    end
end
function UICampaignShopConfirmDetailController:SetCountPriceTxt()
    self.countTxt:SetText(self.count)
    self.countFollowTxt:SetText(self.count)
    self.price = self.count * self.singlePrice
    self.priceTxt:SetText(self.price)
    self:SetTextColor()
end
function UICampaignShopConfirmDetailController:MinOnClick(go)
    self.count = 1
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    self:SetCountPriceTxt()
end
function UICampaignShopConfirmDetailController:RemoveOnClick(go)
    if self.count > 1 then
        self.count = self.count - 1
    else
        self.count = 1
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    self:SetCountPriceTxt()
end
function UICampaignShopConfirmDetailController:AddOnClick(go)
    local ownMoney = ClientCampaignShop.GetMoney(self.saleType)
    local maxCount = math.floor(ownMoney / self.singlePrice)
    if maxCount <= 0 then
        self.count = 1
    else
        self.count = self.count + 1
        if self.count >= maxCount then
            self.count = maxCount
        end
        if self.remainCount >= 0 and self.count >= self.remainCount then
            self.count = self.remainCount
        end
        if self.count >= MAX_COUNT then
            self.count = MAX_COUNT
        end
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundAddUp)
    self:SetCountPriceTxt()
end
function UICampaignShopConfirmDetailController:MaxOnClick(go)
    local ownMoney = ClientCampaignShop.GetMoney(self.saleType)
    local maxCount = math.floor(ownMoney / self.singlePrice)
    if maxCount <= 0 then
        maxCount = 1
    else
        if self.remainCount >= 0 and maxCount >= self.remainCount then
            maxCount = self.remainCount
        end
        if maxCount >= MAX_COUNT then
            maxCount = MAX_COUNT
        end
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundAddUp)
    self.count = maxCount
    self:SetCountPriceTxt()
end
function UICampaignShopConfirmDetailController:BtnbgOnClick(go)
    self:CloseDialog()
end
function UICampaignShopConfirmDetailController:InitPlayerSpine()
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    self._spine:LoadSpine("duya_spine_idle")
end
