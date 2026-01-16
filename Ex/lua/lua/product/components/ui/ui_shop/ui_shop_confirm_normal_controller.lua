--[[
    @商城 普通购买框
]]
---@class UIShopConfirmNormalController:UIController
_class("UIShopConfirmNormalController", UIController)
UIShopConfirmNormalController = UIShopConfirmNormalController

function UIShopConfirmNormalController:Constructor()
    self.atlas = self:GetAsset("UIShop.spriteatlas", LoadType.SpriteAtlas)
    self.uiCommonAtlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end

function UIShopConfirmNormalController:OnShow(uiParams)
    self.goodData = uiParams[1]
    self.subTabType = uiParams[2]
    self._isCancelLoadSpine = uiParams[3] --是否取消加载Spine
    local sop = self:GetUIComponent("UISelectObjectPath", "uiitem")
    ---@type UIItem
    self.uiItem = sop:SpawnObject("UIItem")
    self.uiItem:SetForm(UIItemForm.Base)
    self.nameTxt = self:GetUIComponent("UILocalizationText", "name")
    self._currentCount = self:GetUIComponent("UILocalizationText", "itemCount")
    self.nameTrans = self:GetUIComponent("Transform", "name")
    self.descTxt = self:GetUIComponent("UILocalizationText", "desc")
    self.descRect = self:GetUIComponent("RectTransform", "desc")
    self.btnStarGO = self:GetGameObject("btnstar")
    self.btnGo = self:GetGameObject("btnGo")

    self.moneyIcon = self:GetUIComponent("Image", "moneyicon")
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
    self:InitPlayerSpine()
    self:Refresh()
    -- self:InitBg()
    -- self.blurMaskGO:SetActive(false)
    -- self.blurMask:RefreshBlurTexture()
    -- self.blurMaskGO:SetActive(true)
    -- self.bgGO:SetActive(false)
end
function UIShopConfirmNormalController:SetTextColor()
    local ownMoney = ClientShop.GetMoney(self.saleType)
    if ownMoney >= self.price then
        self.priceTxt.color = Color.black
    else
        self.priceTxt.color = Color.red
    end
end
-- body
function UIShopConfirmNormalController:Refresh()
    if not self.goodData then
        return
    end
    local cfgItem = Cfg.cfg_item[self.goodData:GetItemId()]
    if not cfgItem then
        return
    end
    self.isPet = self.goodData:IsPet()
    self.saleType = self.goodData:GetSaleType()
    self.price = self.goodData:GetSalePrice()

    local itemId = cfgItem.ID
    local icon = cfgItem.Icon
    local quality = cfgItem.Color
    local count = self.goodData:GetItemCount()
    local text1 = count <= 1 and "" or StringTable.Get("str_shop_good_count") .. count
    self.uiItem:SetData({icon = icon, quality = quality, text1 = text1, itemId = itemId})
    self.nameTxt:SetText("「" .. StringTable.Get(cfgItem.Name) .. "」")

    local itemCount = 0
    if self.isPet then
        if self:GetModule(PetModule):GetPetByTemplateId(itemId) ~= nil then
            itemCount = 1
        end
    else
        itemCount = self:GetModule(ItemModule):GetItemCount(itemId)
    end
    self._currentCount:SetText(StringTable.Get("str_shop_current_item_count", itemCount))

    self.descTxt:SetText(StringTable.Get(cfgItem.Intro))
    self.priceTxt:SetText(self.price)
    self:SetTextColor()
    self.moneyIcon.sprite = self.uiCommonAtlas:GetSprite(ClientShop.GetCurrencyImageName(self.saleType))
    if self.isPet then
        --self.nameTrans.localPosition = Vector3(99.1, -83.8)
        self.btnStarGO:SetActive(true)
        self.btnGo:SetActive(true)
    else
        --self.nameTrans.localPosition = Vector3(99.1, -131)
        self.btnStarGO:SetActive(false)
        self.btnGo:SetActive(false)
    end
    self:DoAnimation()
end

function UIShopConfirmNormalController:DoAnimation()
    self._cg = self:GetUIComponent("CanvasGroup", "UICanvas")
    self._panel = self:GetUIComponent("RectTransform", "panel")
    self._infoTrans = self:GetUIComponent("Transform", "info")
    self._cg.alpha = 0

    self:Lock("UIShopConfirmNormalController:DoAnimation")

    self:StartTask(
        function(TT)
            YIELD(TT)
            YIELD(TT)
            self._cg:DOFade(1, 0.3)
            --[[
            local descHeight = self.descRect.sizeDelta.y
            if descHeight < 130 then
                descHeight = 130
            elseif descHeight < 178 then
                descHeight = 178
            end
            if descHeight > 82 and descHeight < 130 then
                self._panel.sizeDelta = Vector2(830, 438)
            elseif descHeight >= 130 and descHeight < 178 then
                self._panel.sizeDelta = Vector2(830, 485)
            elseif descHeight >= 178 then
                self._panel.sizeDelta = Vector2(830, 530)
            end
            --]]
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
                    self:UnLock("UIShopConfirmNormalController:DoAnimation")
                end
            )
        end,
        self
    )
end

function UIShopConfirmNormalController:OnHide()
    if self._spine then
        self._spine:DestroyCurrentSpine()
        self._spine = nil
    end
end

function UIShopConfirmNormalController:btnstarOnClick(go)
    self:ShowDialog("UIShopPetDetailController", self.goodData:GetItemId())
end

function UIShopConfirmNormalController:btnbuyOnClick(go)
    if not ClientShop.CheckBuy(self.saleType, self.price) then
        if self.saleType == RoleAssetID.RoleAssetGlow then
            self:CloseDialog()
        end
        return
    end
    self:StartTask(
        function(TT)
            local shopModule = self:GetModule(ShopModule)
            self:Lock("UIShopConfirmNormalController:btnbuyOnClick")

            local result =
                shopModule:BuyItem(
                TT,
                self.subTabType,
                self.goodData:GetGoodId(),
                1,
                self.saleType,
                self.goodData:GetSalePrice()
            )

            self:UnLock("UIShopConfirmNormalController:btnbuyOnClick")
            if result then
                if ClientShop.CheckShopCode(result) then
                    local roleAsset = RoleAsset:New()
                    roleAsset.assetid = self.goodData:GetItemId()
                    roleAsset.count = self.goodData:GetItemCount()
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

function UIShopConfirmNormalController:btnbgOnClick(go)
    self:CloseDialog()
end

function UIShopConfirmNormalController:InitPlayerSpine()
    if self._isCancelLoadSpine then
        return
    end
    self._spine = self:GetUIComponent("SpineLoader", "spine")
    self._spineGo = self:GetGameObject("spine")
    self._spine:LoadSpine("duya_spine_idle")
end
