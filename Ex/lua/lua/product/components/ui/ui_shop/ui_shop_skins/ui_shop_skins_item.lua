---@class UIShopSkinsItem : UICustomWidget
_class("UIShopSkinsItem", UICustomWidget)
UIShopSkinsItem = UIShopSkinsItem
function UIShopSkinsItem:OnShow(uiParams)
    self.shopModule = self:GetModule(ShopModule)
    self._svrTimeModule = self:GetModule(SvrTimeModule)
    self.clientShop = self.shopModule:GetClientShop()
    ---@type SkinsShopData
    self._data = self.clientShop:GetSkinsShopData()

    self:InitWidget()
end
function UIShopSkinsItem:SetOutTimeClickFunc(clickFunc)
    self._overTimeClickFunc = clickFunc
end
function UIShopSkinsItem:InitWidget()
    self.discount = self:GetGameObject("discount")
    ---@type UILocalizationText
    self.txtDiscount = self:GetUIComponent("UILocalizationText", "txtDiscount")

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

    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "ImgIcon")
    self._restTimeAreaGo = self:GetGameObject("RestTimeArea")
    ---@type UILocalizationText
    self._restTimeText = self:GetUIComponent("UILocalizationText", "RestTimeText")
    ---@type RawImageLoader
    self._logo = self:GetUIComponent("RawImageLoader", "Logo")
    ---@type UILocalizationText
    self._petName = self:GetUIComponent("UILocalizationText", "PetName")
    ---@type UILocalizationText
    self._skinName = self:GetUIComponent("UILocalizationText", "SkinName")
    self._flagAreaGo = self:GetGameObject("FlagArea")
    self._specialFlagAreaGo = self:GetGameObject("SpecialFlagArea")
    self._specialFlagAreaEffGo = self:GetGameObject("SpecialFlagAreaEff")

    ---@type UILocalizationText
    self._flagText = self:GetUIComponent("UILocalizationText", "FlagText")
    ---@type UnityEngine.UI.Image
    self._btnPrice = self:GetUIComponent("Image", "btnPrice")
    self._gotAreaGo = self:GetGameObject("GotArea")
    self.imgNew = self:GetGameObject("imgNew")
    self.imgNew:SetActive(false)

    self._binderSkin = self:GetGameObject("binderSkin")
    self._zg_price = self:GetUIComponent("UILocalizationText", "zg_price")
    self._binder_yj_img = self:GetUIComponent("Image", "yj_img")
    self._yj_price = self:GetUIComponent("UILocalizationText", "yj_price")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
    self:AttachEvent(GameEventType.UpdateSkinsItemPrice, self.FlushPrice)
end
function UIShopSkinsItem:OnHide()
    self:DetachEvent(GameEventType.UpdateSkinsItemPrice, self.FlushPrice)
    self:CancelEvent()
end
function UIShopSkinsItem:CancelEvent()
    if self._event then
        GameGlobal.RealTimer():CancelEvent(self._event)
        self._event = nil
    end
end
function UIShopSkinsItem:SetData()
end
function UIShopSkinsItem:bgOnClick(go)
    if self:_IsOverTime() then
        --弹提示 刷新列表
        if self._overTimeClickFunc then
            self._overTimeClickFunc()
        end
        return
    end
    if self._itemData:IsSeniorSkin() then
        if self._itemData:IsSeniorSkinReview() then
            --高级时装复刻
            -- GameGlobal.GetModule(CampaignModule):GetCurHauteCouture_Review():ShopGoodsOnClick()
            GameGlobal.GetModule(CampaignModule):GetCurHauteCouture_Review(true, function(data)
                data:ShopGoodsOnClick()
            end)
        else
            --普通高级时装
            self:ShowDialog("UIHauteCoutureDrawV2Controller")
        end
    else
        self:ShowDialog("UIPetSkinsMainController", PetSkinUiOpenType.PSUT_SHOP_DETAIL, self._itemData)
    end
    --打开购买详情
    ---new
    self.shopModule:CancelNewMark(MarketType.Shop_SkinMarket, self._itemData:GetId())

    --绑定的物品一起删除new标签
    local binderItem = self._itemData:GetBinderSkin()
    if binderItem ~= nil then
        self.shopModule:CancelNewMark(MarketType.Shop_SkinMarket, binderItem:GetId())
        binderItem:SetNew(false)
    end

    self._itemData:SetNew(false)
    GameGlobal.EventDispatcher():Dispatch(GameEventType.ShopNew)
    self:FlushNew()
end
function UIShopSkinsItem:_IsOverTime()
    local stopTime = self._itemData:GetEndTime()
    if stopTime <= 0 then
        return false
    end
    local nowTime = math.floor(self._svrTimeModule:GetServerTime() / 1000)
    local remainingTime = stopTime - nowTime
    return (remainingTime <= 0)
end
function UIShopSkinsItem:Flush(id)
    self:CancelEvent()

    self._itemData = self._data:GetGoodById(id)
    if not self._itemData then
        return
    end
    self._skinId = self._itemData:GetSkinId()
    local skinCfg = Cfg.cfg_pet_skin[self._skinId]
    if not skinCfg then
        return
    end
    local petCfg = Cfg.cfg_pet[skinCfg.PetId]
    if not petCfg then
        return
    end
    self._skinName:SetText(StringTable.Get(skinCfg.SkinName))
    self._imgIcon:LoadImage(skinCfg.TeamBody)
    self._flagAreaGo:SetActive(skinCfg.SkinType == 2)
    self._specialFlagAreaGo:SetActive(skinCfg.SkinType == 3)
    self._specialFlagAreaEffGo:SetActive(skinCfg.SkinType == 3)
    self._restTimeAreaGo:SetActive(self:IsShowRemainingTime())
    self:_OnValueRemainingTime()

    self._petName:SetText(StringTable.Get(petCfg.Name))
    self._logo:LoadImage(petCfg.Logo)
    self:FlushDiscount()
    self:FlushPrice()
    self:FlushNew()
end
function UIShopSkinsItem:FlushDiscount()
    local discount, discountStr = self._itemData:GetDiscount()
    if discountStr then
        self.discount:SetActive(true)
        self.txtDiscount:SetText(discountStr)
    else
        self.discount:SetActive(false)
    end
end
---@param id number
function UIShopSkinsItem:FlushPrice()
    local isSeniorSkin = self._itemData:IsSeniorSkin()
    self.price:SetActive(false)
    self.priceDiscount:SetActive(false)
    self._binderSkin:SetActive(false)
    self.otherText.gameObject:SetActive(false)

    if isSeniorSkin then
        self.price.gameObject:SetActive(false)
        self.imgPrice.gameObject:SetActive(false)
        self.otherText:SetText(StringTable.Get("str_pay_goto"))
        self.otherText.gameObject:SetActive(true)
        self._gotAreaGo:SetActive(false)
    elseif self._itemData:HasSoldOut() then
        self._gotAreaGo:SetActive(true)
    else
        self._gotAreaGo:SetActive(false)
        local itemtType = self._itemData:GetType()
        self.imgPriceRaw.gameObject:SetActive(false)
        self.imgPrice.gameObject:SetActive(false)
        if itemtType == GiftPackType.Currency then
            self.price:SetActive(true)
            self.price.gameObject:SetActive(true)
            self.txtPrice:SetText(self._itemData:GetPriceWithCurrencySymbol())
        elseif itemtType == GiftPackType.Free then
            self.price.gameObject:SetActive(false)
            self.imgPrice.gameObject:SetActive(false)
            self.otherText:SetText(StringTable.Get("str_pay_free"))
            self.otherText.gameObject:SetActive(true)
        else
            --这里显示绑定直购方式
            local binderItem = self._itemData:GetBinderSkin()
            if binderItem ~= nil then
                self._binderSkin:SetActive(true)
                self._binder_yj_img.sprite = self._atlas:GetSprite(self._itemData:GetPriceIcon())
                self._yj_price:SetText(self._itemData:GetPrice())

                local price = binderItem:GetPriceWithCurrencySymbol()
                self._zg_price:SetText(price)
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
                    self.price.gameObject:SetActive(true)
                    self.txtPrice:SetText(self._itemData:GetPrice())
                end
            end
        end
    end
end
function UIShopSkinsItem:FlushNew()
    local isNew = self._itemData:GetNew()
    self.imgNew:SetActive(isNew)
end

function UIShopSkinsItem:IsShowRemainingTime()
    local stopTime = self._itemData:GetEndTime()
    if stopTime <= 0 then
        return false
    end

    if not self._itemData:GetIsShowLeftTime() then
        return false
    end

    if self._itemData:IsResident() then
        return false
    end

    return true
end

function UIShopSkinsItem:_OnValueRemainingTime()
    if not self:IsShowRemainingTime() then
        self._restTimeAreaGo:SetActive(false)
        return
    end

    self:_ShowRemainingTime()
    self:CancelEvent()
    self._event =
        GameGlobal.RealTimer():AddEventTimes(
        1000,
        TimerTriggerCount.Infinite,
        function()
            self:_ShowRemainingTime()
        end
    )
end
function UIShopSkinsItem:_ShowRemainingTime()
    local stopTime = self._itemData:GetEndTime()
    local nowTime = self._svrTimeModule:GetServerTime() * 0.001
    local remainingTime = stopTime - nowTime
    if remainingTime <= 0 then
        self:CancelEvent()
        self._restTimeAreaGo:SetActive(false)
        remainingTime = 0
    else
        self._restTimeAreaGo:SetActive(true)
    end
    self._restTimeText:SetText(self:_GetFormatString(remainingTime))
end
function UIShopSkinsItem:_GetFormatString(stamp)
    --local formatStr = "%s %s"
    --local descStr = StringTable.Get("str_shop_remain")
    --local colorStr = "FFE42D"

    local timeStr = self:GetFormatTimerStr(stamp)
    --local showStr = string.format(formatStr, descStr, colorStr, timeStr)
    --local showStr = string.format(formatStr, descStr, timeStr)

    return timeStr
end
function UIShopSkinsItem:GetFormatTimerStr(time, id)
    local default_id = {
        ["day"] = "str_pay_left_day",
        ["hour"] = "str_pay_left_hour",
        ["min"] = "str_pay_left_minute",
        ["zero"] = "str_activity_common_less_minute"
    }
    id = id or default_id

    local timeStr = ""
    if time < 0 then
        timeStr = StringTable.Get(id_zero)
        return timeStr
    end
    local day, hour, min, second = UIActivityHelper.Time2Str(time)
    if day > 0 then
        local showDay = day
        timeStr = StringTable.Get(id.day, showDay)
    elseif hour > 0 then
        local showHour = hour
        timeStr = StringTable.Get(id.hour, showHour)
    elseif min > 0 then
        local showMin = min
        timeStr = StringTable.Get(id.min, showMin)
    else
        timeStr = StringTable.Get(id.zero)
    end
    return timeStr
end
