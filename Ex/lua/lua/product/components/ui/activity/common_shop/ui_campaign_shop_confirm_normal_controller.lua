---@class UICampaignShopConfirmNormalController : UIController
_class("UICampaignShopConfirmNormalController", UIController)
UICampaignShopConfirmNormalController = UICampaignShopConfirmNormalController
function UICampaignShopConfirmNormalController:Constructor()
    --self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    --self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end
function UICampaignShopConfirmNormalController:OnShow(uiParams)
    self:InitWidget(uiParams)
end
function UICampaignShopConfirmNormalController:InitWidget(uiParams)
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
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.nameTrans = self:GetUIComponent("Transform", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    self.descRect = self:GetUIComponent("RectTransform", "desc")
    self.descScroll = self:GetUIComponent("ScrollRect", "ContentPanel")
    self.btnGO = self:GetGameObject("btnGo")
    self._currentCount = self:GetUIComponent("UILocalizationText", "itemCount")
    --self.moneyIcon = self:GetUIComponent("Image", "moneyicon")
    self.moneyIconLoader = self:GetUIComponent("RawImageLoader", "moneyicon")
    self.priceTxt = self:GetUIComponent("UILocalizationText", "price")
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
function UICampaignShopConfirmNormalController:SetTextColor()
    local ownMoney = ClientCampaignShop.GetMoney(self.saleType)
    if ownMoney >= self.price then
        self.priceTxt.color = Color.black
    else
        self.priceTxt.color = Color.red
    end
end
-- body
function UICampaignShopConfirmNormalController:Refresh()
    if not self.goodsData then
        return
    end
    local cfgItem = Cfg.cfg_item[self.goodsData:GetItemId()]
    if not cfgItem then
        return
    end
    self.isPet = self.goodsData:IsPet()
    self.saleType = self.goodsData:GetSaleType()
    self.price = self.goodsData:GetSalePrice()

    local itemId = cfgItem.ID
    local icon = cfgItem.Icon
    local quality = cfgItem.Color
    local count = self.goodsData:GetItemCount()
    local text1 = count <= 1 and "" or StringTable.Get("str_shop_good_count") .. count
    self.uiItem:SetData({icon = icon, quality = quality, text1 = text1, itemId = itemId})
    self.nameTxt:SetText("「" .. StringTable.Get(cfgItem.Name) .. "」")
    self.descTxt:SetText(StringTable.Get(cfgItem.Intro))
    self.priceTxt:SetText(self.price)
    self:SetTextColor()

    local itemCount = 0
    if self.isPet then
        if self:GetModule(PetModule):GetPetByTemplateId(itemId) ~= nil then
            itemCount = 1
        end
    else
        itemCount = self:GetModule(ItemModule):GetItemCount(itemId)
    end
    self._currentCount:SetText(StringTable.Get("str_shop_current_item_count", itemCount))

    --self.moneyIcon.sprite = self.uiCommonAtlas:GetSprite(ClientCampaignShop.GetCurrencyImageName(self.saleType))
    self.moneyIconLoader:LoadImage(ClientCampaignShop.GetCurrencyImageName(self.saleType))
    if self.isPet then
        self.btnGO:SetActive(true)
        --self.nameTrans.localPosition = Vector3(99.1, -83.8)
    else
        self.btnGO:SetActive(false)
        --self.nameTrans.localPosition = Vector3(99.1, -131)
    end
    self:DoAnimation()
    self:SetScroll()
end
function UICampaignShopConfirmNormalController:SetScroll()
    local perferredH = self.descTxt.preferredHeight
    if perferredH < 135 then
        self.descScroll.vertical = false
    else
        self.descScroll.vertical = true
    end
end
function UICampaignShopConfirmNormalController:DoAnimation()
    self._cg = self:GetUIComponent("CanvasGroup", "UICanvas")
    self._panel = self:GetUIComponent("RectTransform", "panel")
    self._infoTrans = self:GetUIComponent("Transform", "info")
    self._cg.alpha = 0

    self:StartTask(
        function(TT)
            YIELD(TT)
            YIELD(TT)
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

function UICampaignShopConfirmNormalController:OnHide()
    if self._spine then
        self._spine:DestroyCurrentSpine()
        self._spine = nil
    end
end
function UICampaignShopConfirmNormalController:BtnstarOnClick(go)
    self:ShowDialog("UIShopPetDetailController", self.goodsData:GetItemId())
end
function UICampaignShopConfirmNormalController:BtnbuyOnClick(go)
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
                self:Lock("UICampaignShopConfirmNormalController:btnbuyOnClick")
                local res = AsyncRequestRes:New()
                local rewards = exchangeCmpt:HandleExchangeItem(TT, res, self.goodsData:GetGoodsId(), 1)
                self:UnLock("UICampaignShopConfirmNormalController:btnbuyOnClick")
                if res:GetSucc() then
                    if rewards and #rewards > 0 then
                        local roleAsset = rewards[1]
                        --RoleAsset:New()
                        local assetList = rewards
                        --{roleAsset}
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
                    -- else
                    --     self:CloseDialog()
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
                        -- function()
                        --     self:CloseDialog()
                        -- end
                    )
                    self:CloseDialog()
                end
            end,
            self
        )
    end
end
function UICampaignShopConfirmNormalController:BtnbgOnClick(go)
    self:CloseDialog()
end

function UICampaignShopConfirmNormalController:InitPlayerSpine()
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    self._spine:LoadSpine("duya_spine_idle")
end
