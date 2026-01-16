--[[
    @商城 购买框
]]
---@class UIShopConfirmDetailController:UIController
_class("UIShopConfirmDetailController", UIController)
UIShopConfirmDetailController = UIShopConfirmDetailController
local MAX_COUNT = 99
function UIShopConfirmDetailController:Constructor()
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end

function UIShopConfirmDetailController:OnShow(uiParams)
    self.goodData = uiParams[1]
    self.subTabType = uiParams[2]
    self._isCancelLoadSpine = uiParams[3] --是否取消加载Spine
    self.isPet = self.goodData:IsPet()
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self.nameTrans = self:GetUIComponent("Transform", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    self.descRect = self:GetUIComponent("RectTransform", "desc")
    self.btnStarGO = self:GetGameObject("btnstar")
    self.btnGo = self:GetGameObject("btnGo")

    self.countGroupGO = self:GetGameObject("countgroup")
    self.countGroupRect = self:GetUIComponent("RectTransform", "countgroup")
    self._currentCount = self:GetUIComponent("UILocalizationText", "itemCount")
    self.moneyIcon = self:GetUIComponent("Image", "moneyicon")
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
    self:InitPlayerSpine()
    self:Refresh()
end

function UIShopConfirmDetailController:SetTextColor()
    local ownMoney = ClientShop.GetMoney(self.saleType)
    if ownMoney >= self.price then
        self.priceTxt.color = Color.black
    else
        self.priceTxt.color = Color.red
    end
end

-- body
function UIShopConfirmDetailController:Refresh()
    if not self.goodData then
        return
    end
    local cfgItem = Cfg.cfg_item[self.goodData:GetItemId()]
    if not cfgItem then
        return
    end
    self.count = 1
    self.singlePrice = self.goodData:GetSalePrice()
    local itemId = cfgItem.ID
    local icon = cfgItem.Icon
    local quality = cfgItem.Color
    local count = self.goodData:GetItemCount()
    local text1 = count <= 1 and "" or StringTable.Get("str_shop_good_count") .. count
    self.uiItem:SetData({icon = icon, quality = quality, text1 = text1, itemId = itemId})
    self.nameTxt:SetText("「" .. StringTable.Get(cfgItem.Name) .. "」")

    local itemCount = self:GetModule(ItemModule):GetItemCount(itemId)
    self._currentCount:SetText(StringTable.Get("str_shop_current_item_count", itemCount))

    self.descTxt:SetText(StringTable.Get(cfgItem.Intro))
    self.saleType = self.goodData:GetSaleType()
    self.moneyIcon.sprite = self.uiCommonAtlas:GetSprite(ClientShop.GetCurrencyImageName(self.saleType))
    if self.isPet then
        --self.nameTrans.localPosition = Vector3(95.6, -72)
        self.btnStarGO:SetActive(true)
        self.btnGo:SetActive(true)
    else
        --self.nameTrans.localPosition = Vector3(95.6, -117)
        self.btnStarGO:SetActive(false)
        self.btnGo:SetActive(false)
    end
    self.remainCount = self.goodData:GetRemainCount()
    self.countGroupGO:SetActive(true)
    if self.goodData:IsUnLimit() then
        self.remainGO:SetActive(false)
        self.countGroupRect.anchoredPosition = Vector2(0, 151)
    else
        self.remainGO:SetActive(true)
        self.remainTxt:SetText(self.remainCount)
        self.countGroupRect.anchoredPosition = Vector2(0, 169)
    end
    self:SetCountPriceTxt()

    self:DoAnimation()
end

function UIShopConfirmDetailController:DoAnimation()
    self._cg = self:GetUIComponent("CanvasGroup", "UICanvas")
    self._panel = self:GetUIComponent("RectTransform", "panel")
    self._infoTrans = self:GetUIComponent("Transform", "info")
    self._cg.alpha = 0

    self:Lock("UIShopConfirmDetailController:DoAnimation")
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

            GameGlobal.Timer():AddEvent(
                400,
                function()
                    self:UnLock("UIShopConfirmDetailController:DoAnimation")
                end
            )
        end,
        self
    )
end
function UIShopConfirmDetailController:OnHide()
    if self._spine then
        self._spine:DestroyCurrentSpine()
        self._spine = nil
    end
end

function UIShopConfirmDetailController:btnstarOnClick(go)
    self:ShowDialog("UIShopPetDetailController", self.goodData:GetItemId())
end
-- request.market_type = market_type
-- request.goods_id = goods_id
-- request.buy_num = buy_num
-- request.currency_type = currency_type
-- request.selling_price = selling_price
-- request.discount = discount
function UIShopConfirmDetailController:btnbuyOnClick(go)
    if not ClientShop.CheckBuy(self.saleType, self.price) then
        if self.saleType == RoleAssetID.RoleAssetGlow then
            self:CloseDialog()
        end
        return
    end
    self:StartTask(
        function(TT)
            local shopModule = self:GetModule(ShopModule)
            self:Lock("UIShopConfirmDetailController:btnbuyOnClick")

            local result =
                shopModule:BuyItem(
                TT,
                self.subTabType,
                self.goodData:GetGoodId(),
                self.count,
                self.saleType,
                self.goodData:GetSalePrice()
            )

            self:UnLock("UIShopConfirmDetailController:btnbuyOnClick")
            if result then
                if ClientShop.CheckShopCode(result) then
                    local roleAsset = RoleAsset:New()
                    roleAsset.assetid = self.goodData:GetItemId()
                    roleAsset.count = self.count * self.goodData:GetItemCount()
                    -- GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopBuySuccess)

                    local assetList = {roleAsset}
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
                                            GameEventType.ShopBuySuccess,
                                            self.goodData:GetGoodId()
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
                                    GameEventType.ShopBuySuccess,
                                    self.goodData:GetGoodId()
                                )
                            end
                        )
                        self:CloseDialog()
                    end
                end
            end
        end,
        self
    )
end

function UIShopConfirmDetailController:SetCountPriceTxt()
    self.countTxt:SetText(self.count)
    self.countFollowTxt:SetText(self.count)
    self.price = self.count * self.singlePrice
    self.priceTxt:SetText(self.price)
    self:SetTextColor()
end
function UIShopConfirmDetailController:minOnClick(go)
    self.count = 1
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    self:SetCountPriceTxt()
end
function UIShopConfirmDetailController:removeOnClick(go)
    if self.count > 1 then
        self.count = self.count - 1
    else
        self.count = 1
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundDecDown)
    self:SetCountPriceTxt()
end
function UIShopConfirmDetailController:addOnClick(go)
    local ownMoney = ClientShop.GetMoney(self.saleType)
    local maxCount = math.floor(ownMoney / self.singlePrice)
    if maxCount <= 0 then
        self.count = 1
    else
        self.count = self.count + 1
        if self.count >= maxCount then
            self.count = maxCount
        end
        if self.count >= self.remainCount then
            self.count = self.remainCount
        end
        if self.count >= MAX_COUNT then
            self.count = MAX_COUNT
        end
    end
    AudioHelperController.PlayUISoundAutoRelease(CriAudioIDConst.SoundAddUp)
    self:SetCountPriceTxt()
end
function UIShopConfirmDetailController:maxOnClick(go)
    local ownMoney = ClientShop.GetMoney(self.saleType)
    local maxCount = math.floor(ownMoney / self.singlePrice)
    if maxCount <= 0 then
        maxCount = 1
    else
        if maxCount >= self.remainCount then
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

function UIShopConfirmDetailController:btnbgOnClick(go)
    self:CloseDialog()
end

function UIShopConfirmDetailController:InitPlayerSpine()
    if self._isCancelLoadSpine then
        return
    end
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    self._spine:LoadSpine("duya_spine_idle")
end
