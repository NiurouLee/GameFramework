---@class UIShopGiftPackItem:UICustomWidget
_class("UIShopGiftPackItem", UICustomWidget)
UIShopGiftPackItem = UIShopGiftPackItem

function UIShopGiftPackItem:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetGiftPackShopData()
end

function UIShopGiftPackItem:OnShow()
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._label = self:GetGameObject("label")
    self._txtLabel = self:GetUIComponent("UILocalizationText", "txtLabel")
    self._goTips = self:GetGameObject("tips")
    ---@type UILocalizationText
    self._txtTips = self:GetUIComponent("UILocalizationText", "txtTips")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    self.goRefresh = self:GetGameObject("refresh")
    ---@type UILocalizationText
    self.txRefresh = self:GetUIComponent("RollingText", "txRefresh")
    self._goLimit = self:GetGameObject("limit")
    self._goLimit:SetActive(false)
    ---@type UILocalizationText
    self._txtLimit = self:GetUIComponent("RollingText", "txtLimit")
    self.price = self:GetGameObject("price")
    self.priceDiscount = self:GetGameObject("priceDiscount")
    ---@type UILocalizationText
    self.txtPrice = self:GetUIComponent("UILocalizationText", "txtPrice")
    ---@type UnityEngine.UI.Image
    self.imgPrice = self:GetUIComponent("Image", "imgPrice")
    ---@type UILocalizationText
    self.txtPriceRaw = self:GetUIComponent("UILocalizationText", "txtPriceRaw")
    ---@type UILocalizationText
    self.txtPriceDiscount = self:GetUIComponent("UILocalizationText", "txtPriceDiscount")
    ---@type UnityEngine.UI.Image
    self.imgPriceRaw = self:GetUIComponent("Image", "imgPriceRaw")

    ---@type UILocalizationText
    self.otherText = self:GetUIComponent("UILocalizationText", "otherText")

    self._goSoldout = self:GetGameObject("soldout")
    self._goSoldout:SetActive(false)
    self._goLock = self:GetGameObject("lock")
    self._goLock:SetActive(false)

    self._redpoint = self:GetGameObject("redpoint")
    self._redpoint:SetActive(false)
    self.imgNew = self:GetGameObject("imgNew")
    self.imgNew:SetActive(false)

    self._goPaid = self:GetGameObject("paid")
    ---@type UILocalizationText
    self.paidText = self:GetUIComponent("UILocalizationText", "txtPaid")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.UpdateGiftPackItemPrice, self.FlushPrice)
    self:AttachEvent(GameEventType.CheckMonthCardRedpoint, self._CheckMonthCardRedpoint)
end

function UIShopGiftPackItem:OnHide()
    self:DetachEvent(GameEventType.UpdateGiftPackItemPrice, self.FlushPrice)
    self:DetachEvent(GameEventType.CheckMonthCardRedpoint, self._CheckMonthCardRedpoint)
end

---@param id number
function UIShopGiftPackItem:Flush(id)
    self._itemData = self._data:GetGoodBuyId(id)
    self._txtName:SetText(self._itemData:GetName())
    local discount, discountStr = self._itemData:GetDiscount()
    if discountStr then
        self._label:SetActive(true)
        self._txtLabel:SetText(discountStr)
    else
        self._label:SetActive(false)
    end
    local str = self._itemData:GetCountStr()
    if string.isnullorempty(str) then
        self._goLimit:SetActive(false)
    else
        self._txtLimit:RefreshText(str)
        self._goLimit:SetActive(true)
    end
    local strCycleType = self._itemData:GetCycleTypeStr()
    if string.isnullorempty(strCycleType) then
        self._goTips:SetActive(false)
    else
        self._goTips:SetActive(true)
        self._txtTips:SetText(strCycleType)
    end
    local s = self._itemData:GetRefreshTimeStr()
    if string.isnullorempty(s) then
        self.goRefresh:SetActive(false)
    else
        self.goRefresh:SetActive(true)
        self.txRefresh:RefreshText(s)
    end

    self._imgIcon:LoadImage(self._itemData:GetIcon())
    if self._itemData:HasSoldOut() then
        self._goSoldout:SetActive(true)
    else
        self._goSoldout:SetActive(false)
    end

    local isLock = false
    if self._itemData:IsLevelGift() and self._itemData:IsLevelGiftLock() then
        local txt = StringTable.Get("str_pay_level_gift_lock", self._itemData:GetLevelGiftLockLv())
        UIWidgetHelper.SetLocalizationText(self, "txtLock", txt)
        isLock = true
    end

    self._goPaid:SetActive(false)
    if self._itemData:GetRechargeGift()  then
        local data =  self._itemData:GetAwardsImmediately()
        if next(data) then 
            self._goPaid:SetActive(true)
            self.paidText:SetText(data[1]:GetCount())
        end 
    end

    self._goLock:SetActive(isLock)

    self:FlushPrice()

    self._redpoint:SetActive(false)
    self:_CheckMonthCardRedpoint()
    self:_CheckLevelGiftRedpoint()

    self:FlushNew()
end

---@param id number
function UIShopGiftPackItem:FlushPrice()
    if not self._itemData then
        return
    end
    local isBattlePassGift = self._itemData:IsBattlePassGift()
    local itemtType = self._itemData:GetType()
    self.price:SetActive(false)
    self.priceDiscount:SetActive(false)
    self.imgPriceRaw.gameObject:SetActive(false)
    self.imgPrice.gameObject:SetActive(false)
    self.otherText.gameObject:SetActive(false)

    if isBattlePassGift then
        self.price:SetActive(true)
        self.txtPrice.gameObject:SetActive(false)
        self.otherText:SetText(StringTable.Get("str_pay_goto"))
        self.otherText.gameObject:SetActive(true)
    elseif itemtType == GiftPackType.Currency then
        self.price:SetActive(true)
        self.txtPrice.gameObject:SetActive(true)
        self.txtPrice:SetText(self._itemData:GetPriceWithCurrencySymbol())
    elseif itemtType == GiftPackType.Free then
        self.price:SetActive(true)
        self.txtPrice.gameObject:SetActive(false)
        self.otherText:SetText(StringTable.Get("str_pay_free"))
        self.otherText.gameObject:SetActive(true)
    else
        local discount, discountStr = self._itemData:GetDiscount()
        if discount then
            self.priceDiscount:SetActive(true)
            self.imgPriceRaw.gameObject:SetActive(true)
            self.imgPriceRaw.sprite = self._atlas:GetSprite(self._itemData:GetPriceIcon())
            self.txtPriceRaw:SetText(self._itemData:GetPriceRaw())
            self.txtPriceDiscount:SetText(self._itemData:GetPrice())
        else
            self.price:SetActive(true)
            self.imgPrice.gameObject:SetActive(true)
            self.imgPrice.sprite = self._atlas:GetSprite(self._itemData:GetPriceIcon())
            self.txtPrice.gameObject:SetActive(true)
            self.txtPrice:SetText(self._itemData:GetPrice())
        end
    end
end

function UIShopGiftPackItem:_CheckLevelGiftRedpoint()
    if self._itemData and self._itemData:IsLevelGift() then
        local show = self._itemData:IsLevelGiftRed()
        self._redpoint:SetActive(show)
    end
end

--
function UIShopGiftPackItem:_CheckMonthCardRedpoint()
    if self._itemData and self._itemData:IsMonthCard() then
        local show,tips, day = self.shopModule:ShowMonthCardRedPoint()
        self._day = day
        self._redpoint:SetActive(show)
    end
end

function UIShopGiftPackItem:FlushNew()
    local isNew = self._itemData:GetNew()
    if self._itemData:GetRechargeGift() then
        local key = "UIShopGiftPackItem"..self:GetNewFlagKey(self._itemData:GetId()) 
        isNew = LocalDB.GetInt(key, 0) == 0 
        self.imgNew:SetActive(isNew)
    else 
        self.imgNew:SetActive(isNew)
    end
end

function UIShopGiftPackItem:bgOnClick()
    self:OpenUIShopGiftPackDetail()
end

function UIShopGiftPackItem:btnPriceOnClick()
    self:OpenUIShopGiftPackDetail()
end

function UIShopGiftPackItem:OpenUIShopGiftPackDetail()
    if self._goLock.activeSelf then
        return
    end
    local isBattlePassGift = self._itemData:IsBattlePassGift()
    if isBattlePassGift then
        self:ShowDialog(
            "UIActivityBattlePassN5BuyController",
            function()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateGiftPackShop)
            end
        )
    else
        self:_RecordClick()
        if self._itemData:GetType() == GiftPackType.Currency then
            GameGlobal.GetUIModule(ShopModule):ReportPayStep(
                PayStep.LaunchPurchaseUI,
                true,
                0,
                tostring(self._itemData:GetId())
            )
        end
        self:ShowDialog("UIShopGiftPackDetail", self._itemData:GetId())
        --new
        if self._itemData:GetNew() then
            self.shopModule:CancelNewMark(MarketType.Shop_GiftMarket, self._itemData:GetId())
            self._itemData:SetNew(false)
        end
        if self._itemData:GetRechargeGift() then 
            self.shopModule:CancelRechargeGiftNewMark( self._itemData:GetId())
            self._itemData:SetNew(false)
        end 
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopNew)
        self:FlushNew()
    end
end

function UIShopGiftPackItem:_RecordClick()
    if self._itemData:IsMonthCard() then
        local isRed, tips, state = self.shopModule:ShowMonthCardRedPoint()
        if isRed then
            local monthCardInfo = self.shopModule:GetMonthCardInfo()
            local key 
            if state == 2 then
                key = self.shopModule:GetMonthCardWillOutDataRedKey(monthCardInfo)
            elseif state == 3 then
                key = self.shopModule:GetMonthCardOutDataRedKey(monthCardInfo)
            end
            if key then
                LocalDB.SetInt(key, 1)
                GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckMonthCardRedpoint) 
            end
        end
    end
end
function UIShopGiftPackItem:GetNewFlagKey(id)
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local pstId = roleModule:GetPstId()
    local key = pstId .. id
    return key
end

