---@class UIActivityGiftPackDetail:UIController
_class("UIActivityGiftPackDetail", UIController)
UIActivityGiftPackDetail = UIActivityGiftPackDetail

function UIActivityGiftPackDetail:_GetComponents()
    ---@type UILocalizationText
    self._txtName = self:GetUIComponent("UILocalizationText", "txtName")
    self._goTips = self:GetGameObject("tips")
    ---@type UILocalizationText
    self._txtTips = self:GetUIComponent("UILocalizationText", "txtTips")
    ---@type RawImageLoader
    self._imgIcon = self:GetUIComponent("RawImageLoader", "imgIcon")
    ---@type UnityEngine.GameObject
    self._goLimit = self:GetGameObject("limit")
    self._goLimit:SetActive(false)
    ---@type UILocalizationText
    self._txtLimit = self:GetUIComponent("UILocalizationText", "txtLimit")
    ---@type UnityEngine.UI.Image
    self._imgPrice = self:GetUIComponent("Image", "imgPrice")
    ---@type UILocalizationText
    self._txtPrice = self:GetUIComponent("UILocalizationText", "txtPrice")
    ---@type UICustomWidgetPool
    self._sopImmediately = self:GetUIComponent("UISelectObjectPath", "sopImmediately")
    ---@type UICustomWidgetPool
    self._sopDaily = self:GetUIComponent("UISelectObjectPath", "sopDaily")
    self._goDaily = self:GetGameObject("daily")
    ---@type UnityEngine.UI.Button
    self._btnBuy = self:GetUIComponent("Button", "btnBuy")
    ---@type UnityEngine.Animation
    self._anim = self:GetUIComponent("Animation", "uiAnim")

    ---@type UnityEngine.U2D.SpriteAtlas
    self._atlas = self:GetAsset("UICommon.spriteatlas", LoadType.SpriteAtlas)
end

--- uiParams[1] table self._campaign
--- uiParams[2] BuyGiftComponent self._component
--- uiParams[3] number self._giftId
--- uiParams[3] number self._giftNum
--- uiParams[4] function(res)
function UIActivityGiftPackDetail:OnShow(uiParams)
    self:_AttachEvents()

    self._campaign = uiParams[1]
    ---@type BuyGiftComponent
    self._component = uiParams[2]
    self._giftId = uiParams[3]
    self._giftNum = uiParams[4]
    self._callback = uiParams[5]

    self:_GetComponents()

    self:_SetTitle()
    self:_SetTips()
    self:_SetImg()
    self:_SetLimit()
    self:_SetPrice()
    self:_SetAwardsImmediately()
    self:_SetAwardsDaily()
end

function UIActivityGiftPackDetail:OnHide()
    self:_DetachEvents()
end

function UIActivityGiftPackDetail:_SetTitle()
    local gift = self._component:GetGiftCfgById(self._giftId)
    local id = gift and gift.Name[1] or ""

    self._txtName:SetText(StringTable.Get(id))
end

function UIActivityGiftPackDetail:_SetTips()
    if self._campaign and self._campaign._sample then
        local strCycleType = self:GetCycleTypeStr()

        self._txtTips:SetText(strCycleType)
        self._goTips:SetActive(true)
    else
        self._goTips:SetActive(false)
    end
end

function UIActivityGiftPackDetail:_SetImg()
    local gift = self._component:GetGiftCfgById(self._giftId)
    local url = gift and gift.IconDetail or ""

    self._imgIcon:LoadImage(url)
end

function UIActivityGiftPackDetail:_SetLimit()
    local str = self:GetCountStr()
    if string.isnullorempty(str) then
        self._goLimit:SetActive(false)
    else
        self._txtLimit:SetText(str)
        self._goLimit:SetActive(true)
    end
end

function UIActivityGiftPackDetail:_SetPrice()
    self._txtPrice.color = Color.white
    self._btnBuy.interactable = true

    self:_FlushPrice()
end

function UIActivityGiftPackDetail:_FlushPrice()
    -- 显示用带货币符号的字符串
    local price = self._component:GetGiftPriceForShowById(self._giftId)

    local itemtType = self:GetPriceType()
    if itemtType == GiftPackType.Currency then
        self._imgPrice.gameObject:SetActive(false)
        self._txtPrice:SetText(price)
    elseif itemtType == GiftPackType.Free then
        self._imgPrice.gameObject:SetActive(false)
        self._txtPrice:SetText(StringTable.Get("str_pay_free"))
    else
        self._imgPrice.gameObject:SetActive(true)
        self._imgPrice.sprite = self._atlas:GetSprite(self:GetPriceIcon())
        self._txtPrice:SetText(price)
    end
end

function UIActivityGiftPackDetail:_SetAwardsImmediately()
    local lst = self._component:GetGiftExtraAwardById(self._giftId)

    local awardsImmediately = {}
    for i, item in ipairs(lst) do
        local item = GiftPackShopItemAward:New(item.assetid, item.count)
        table.insert(awardsImmediately, item)
    end

    self._sopImmediately:SpawnObjects("UIActivityGiftPackGetItem", table.count(awardsImmediately))
    ---@type UIActivityGiftPackGetItem[]
    local lstImmediately = self._sopImmediately:GetAllSpawnList()
    for i, ui in ipairs(lstImmediately) do
        ui:Flush(awardsImmediately[i])
    end
end

function UIActivityGiftPackDetail:_SetAwardsDaily()
    -- local awardsDaily = self._itemData:GetAwardsDaily()
    -- if awardsDaily and table.count(awardsDaily) > 0 then
    --     self._goDaily:SetActive(true)
    --     self._sopDaily:SpawnObjects("UIActivityGiftPackGetItem", table.count(awardsDaily))
    --     ---@type UIActivityGiftPackGetItem[]
    --     local lstDaily = self._sopDaily:GetAllSpawnList()
    --     for i, ui in ipairs(lstDaily) do
    --         ui:Flush(awardsDaily[i])
    --     end
    -- else
    self._goDaily:SetActive(false)
    -- end
end

--region Helper
--计算到期时间
function UIActivityGiftPackDetail:GetEndTime()
    return self._campaign and self._campaign._sample and self._campaign._sample.end_time or 0
end

--计算剩余秒数
function UIActivityGiftPackDetail:GetLeftSeconds()
    local mSvrTime = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = mSvrTime:GetServerTime() / 1000 --当前时间戳
    local endTime = self:GetEndTime() --到期时间戳
    local leftSeconds = endTime - nowTime --到截止日的秒数
    return leftSeconds
end

--计算剩余时间
function UIActivityGiftPackDetail:GetCycleTypeStr()
    local str = ""
    local leftSeconds = self:GetLeftSeconds()
    if leftSeconds <= 0 then --已过期
        str = StringTable.Get("str_pay_expired")
    elseif leftSeconds <= 60 then --剩余1分钟
        str = string.format(StringTable.Get("str_pay_left_minute", 1))
    elseif leftSeconds <= 3600 then --剩余N分钟
        local leftMinutes = math.ceil(leftSeconds / 60)
        str = string.format(StringTable.Get("str_pay_left_minute", leftMinutes))
    elseif leftSeconds <= 86400 then --剩余N小时
        local leftHours = math.ceil(leftSeconds / 3600)
        str = string.format(StringTable.Get("str_pay_left_hour", leftHours))
    else --剩余N天
        local leftDays = math.ceil(leftSeconds / 86400)
        str = string.format(StringTable.Get("str_pay_left_day", leftDays))
    end
    return str
end

--计算限购
function UIActivityGiftPackDetail:GetCountStr()
    local buyCount, saleCount = self._component:GetGiftBuyCount(self._giftId)
    if saleCount == SpecialNum.MysteryGoodsUnlimitedNum then
        return ""
    end
    local n2m = (saleCount - buyCount) .. "/" .. saleCount
    local strLimit = string.format(StringTable.Get("str_pay_purchase_limitation_normal", n2m)) -- 限购
    return strLimit
end

--计算购买类型
function UIActivityGiftPackDetail:GetPriceType()
    local good = self._component:GetGoodCfgById(self._giftId)
    local saleType = good and good.SaleType or SpecialNum.FreeGiftSaleType

    local tb = {
        [SpecialNum.NeedPayMoney] = GiftPackType.Currency,
        [RoleAssetID.RoleAssetDiamond] = GiftPackType.Yaojing,
        [RoleAssetID.RoleAssetGlow] = GiftPackType.Guangpo,
        [SpecialNum.FreeGiftSaleType] = GiftPackType.Free
    }
    return tb[saleType] or GiftPackType.Item
end

--计算购买类型图标
function UIActivityGiftPackDetail:GetPriceIcon()
    local good = self._component:GetGoodCfgById(self._giftId)
    local saleType = good.SaleType

    return "toptoon_" .. saleType
end
--endregion

--region Event Callback
function UIActivityGiftPackDetail:bgOnClick(go)
    self:Lock("UIActivityGiftPackDetail:OnHide")
    self._anim:Play("Uieff_UIActivityGiftPackDetail_Out")
    self:StartTask(
        function(TT)
            YIELD(TT, 667)
            self:UnLock("UIActivityGiftPackDetail:OnHide")
            self:CloseDialog()
        end,
        self
    )
end

function UIActivityGiftPackDetail:btnBuyOnClick(go)
    self._component:BuyGift(self._giftId, self._giftNum)
end
--endregion

--region AttachEvent
function UIActivityGiftPackDetail:_AttachEvents()
    self:AttachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:AttachEvent(GameEventType.ActivityCurrencyBuySuccess, self._OnCurrencyBuySuccess)
    self:AttachEvent(GameEventType.ActivityNormalBuyResult, self._OnNormalBuyResult)
end

function UIActivityGiftPackDetail:_DetachEvents()
    self:DetachEvent(GameEventType.ActivityCloseEvent, self._CheckActivityClose)
    self:DetachEvent(GameEventType.ActivityCurrencyBuySuccess, self._OnCurrencyBuySuccess)
    self:DetachEvent(GameEventType.ActivityNormalBuyResult, self._OnNormalBuyResult)
end

function UIActivityGiftPackDetail:_CheckActivityClose(id)
    if self._campaign and self._campaign._id == id then
        self:SwitchState(UIStateType.UIMain)
    end
end

function UIActivityGiftPackDetail:_OnCurrencyBuySuccess(id)
    -- 直购的回调
    if self._giftId == id then
        if self._callback then
            local res = AsyncRequestRes:New()
            res:SetSucc(true)
            self._callback(res)
        end

        self:bgOnClick()
    end
end

function UIActivityGiftPackDetail:_OnNormalBuyResult(gift_id, res)
    -- 活动 普通购买 的回调
    if self._giftId == gift_id then
        if self._callback then
            self._callback(res)
        end

        self:bgOnClick()
    end
end
--endregion
