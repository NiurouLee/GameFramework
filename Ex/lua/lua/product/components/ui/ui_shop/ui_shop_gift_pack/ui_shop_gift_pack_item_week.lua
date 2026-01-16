---@class UIShopGiftPackItemWeek:UICustomWidget
_class("UIShopGiftPackItemWeek", UICustomWidget)
UIShopGiftPackItemWeek = UIShopGiftPackItemWeek

function UIShopGiftPackItemWeek:Constructor()
    self.shopModule = self:GetModule(ShopModule)
    self.clientShop = self.shopModule:GetClientShop()
    self._data = self.clientShop:GetGiftPackShopData()
end

function UIShopGiftPackItemWeek:OnShow()
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._label = self:GetGameObject("label")
    self._txtLabel = self:GetUIComponent("UILocalizationText", "txtLabel")

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
    self.otherText = self:GetUIComponent("UILocalizationText", "otherText")

    --region hint
    ---@type UILocalizationText
    self.txtLeft = self:GetUIComponent("UILocalizationText", "txtLeft")
    self.notBuy = self:GetGameObject("notBuy")
    self._goLimit = self:GetGameObject("limit")
    self._goLimit:SetActive(false)
    ---@type RollingText
    self._txtLimit = self:GetUIComponent("RollingText", "txtLimit")
    --endregion

    self._redpoint = self:GetGameObject("redpoint")
    self._redpoint:SetActive(false)
    self.imgNew = self:GetGameObject("imgNew")
    self.imgNew:SetActive(false)
    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.UpdateGiftPackItemPrice, self.FlushPrice)
end

function UIShopGiftPackItemWeek:OnHide()
    self._imgIcon:DestoryLastImage()
    self:DetachEvent(GameEventType.UpdateGiftPackItemPrice, self.FlushPrice)
end

---@param id number
function UIShopGiftPackItemWeek:Flush(id)
    self._itemData = self._data:GetGoodBuyId(id)
    self._txtName:SetText(self._itemData:GetName())
    local discount, discountStr = self._itemData:GetDiscount()
    if discountStr then
        self._label:SetActive(true)
        self._txtLabel:SetText(discountStr)
    else
        self._label:SetActive(false)
    end

    self._imgIcon:LoadImage(self._itemData:GetIcon())
    self:FlushTxtLeft()
    self:FlushHint()
    self:FlushPrice()
    self:FlushNew()
end

function UIShopGiftPackItemWeek:FlushTxtLeft()
    local LeftDays = function(t, obtained)
        -- local d, h, m, s = UICommonHelper.S2DHMS(t)
        -- local leftDays = math.ceil(d)
        -- return leftDays

        local d, h, m, s = UICommonHelper.S2DHMS(t)
        if d >= 1 then
            if obtained then
                return StringTable.Get("str_pay_left_times", math.ceil(d))
            else
                return StringTable.Get("str_pay_left_day", math.floor(d))
            end
        else
            if obtained then
                local times = 1
                if math.abs(d) <= 1e-5 then
                    times = 0
                end
                --MSG65563	（QA_李钰琦）国服n0同步n32 周卡月卡到期显示优化(客户端）	5	QA-待制作	靳策, jince	06/20/2023	
                return StringTable.Get("str_pay_left_times", times) --购买后剩余时间小于1天 不显示小时数 显示剩余1天
            end
            if h >= 1 then
                return StringTable.Get("str_pay_left_hour", math.floor(h))
            else
                if m >= 1 then
                    return StringTable.Get("str_pay_left_minute", math.floor(m))
                else
                    return StringTable.Get("str_pay_left_minute", "<1")
                end
            end
        end
    end
    local str = ""
    if self._itemData:GetBuyCount() > 0 then --购买数量＞0，表示已购买，显示剩余领取N天
        self.notBuy:SetActive(false)
        local stampRefresh = self._itemData:GetRefreshTime()
        str = LeftDays(stampRefresh, true)
    else --尚未购买，显示剩余N天
        self.notBuy:SetActive(true)
        local stampEnd = self._itemData:GetEndTime()
        local stampNow = UICommonHelper.GetNowTimestamp()
        str = LeftDays(stampEnd - stampNow, false)
    end
    self.txtLeft:SetText(str)
end

function UIShopGiftPackItemWeek:FlushHint()
    local str = ""
    if self._itemData:HasSoldOut() then
        str = StringTable.Get("str_pay_soldout")
    else
        str = self._itemData:GetCountStr()
    end
    if string.isnullorempty(str) then
        self._goLimit:SetActive(false)
    else
        self._txtLimit:RefreshText(str)
        self._goLimit:SetActive(true)
    end
end
---@param id number
function UIShopGiftPackItemWeek:FlushPrice()
    if not self._itemData then
        Log.warn("### _itemData is nil.")
        return
    end
    self.price:SetActive(false)
    self.priceDiscount:SetActive(false)
    self.imgPriceRaw.gameObject:SetActive(false)
    self.imgPrice.gameObject:SetActive(false)
    self.otherText.gameObject:SetActive(false)
    if self._itemData:HasSoldOut() then
        self.price:SetActive(true)
        self.txtPrice:SetText(StringTable.Get("str_pay_soldout"))
        return
    end
    local itemtType = self._itemData:GetType()
    if itemtType == GiftPackType.Currency then
        self.price:SetActive(true)
        self.txtPrice.gameObject:SetActive(true)
        self.txtPrice:SetText(self._itemData:GetPriceWithCurrencySymbol())
    elseif itemtType == GiftPackType.Free then
        self.otherText:SetText(StringTable.Get("str_pay_free"))
        self.otherText.gameObject:SetActive(true)
        self.price:SetActive(true)
        self.txtPrice.gameObject:SetActive(false)
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
            self.txtPrice:SetText(self._itemData:GetPrice())
        end
    end
end

function UIShopGiftPackItemWeek:FlushNew()
    local isNew = self._itemData:GetNew()
    self.imgNew:SetActive(isNew)
end

function UIShopGiftPackItemWeek:bgOnClick()
    self:OpenUIShopGiftPackDetail()
end

function UIShopGiftPackItemWeek:btnPriceOnClick()
    self:OpenUIShopGiftPackDetail()
end

function UIShopGiftPackItemWeek:OpenUIShopGiftPackDetail()
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
        GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopNew)
        self:FlushNew()
    end
end

function UIShopGiftPackItemWeek:_RecordClick()
    if self._itemData:IsMonthCard() then
        LocalDB.SetInt("Month_Card_Red_Point_Click", self._day)
        GameGlobal.EventDispatcher():Dispatch(GameEventType.CheckMonthCardRedpoint)
    end
end
