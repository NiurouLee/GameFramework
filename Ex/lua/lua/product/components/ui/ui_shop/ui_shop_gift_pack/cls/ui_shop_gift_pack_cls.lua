--region GiftPackShopData 礼包商店数据类
---@class GiftPackShopData:Object
---@field _goods GiftPackShopItem[] 礼包列表
_class("GiftPackShopData", Object)
GiftPackShopData = GiftPackShopData

function GiftPackShopData:Constructor()
    self._goods = {}
    self._goodPriceList = {} --商品价格字典
    self._mPay = GameGlobal.GetModule(PayModule)
end

---@param marketInfo GiftMarketInfo
---@param cfgs ConfigKey[] k=id;v=ConfigKey
function GiftPackShopData:UpdateByServerData(marketInfo, cfgs)
    if not marketInfo then
        Log.fatal("### marketInfo nil.")
        return
    end
    local srvTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(srvTimeModule:GetServerTime() / 1000)
    local goodPriceList = self._mPay:GetGoodPriceList()
    self._goods = {}
    ---@type MonthGiftGoodsInfo[]
    local serGoods = marketInfo.goods
    local productList = {}
    for i, good in ipairs(serGoods) do
        local id = good.gift_id
        local cfgv = cfgs[id]
        local cfgClient = Cfg.cfg_shop_giftmarket_goods[id] --确保服务器客户端配置不一致时，只显示客户端配置的礼包
        if cfgv and cfgClient then
            local item = GiftPackShopItem:New(id)
            local midasId = cfgv[ConfigKey.ConfigKey_MidasItemId]
            item:SetMidasId(midasId)
            item:SetBuyCount(good.selled_num)
            local maxBuyCount = tonumber(cfgv[ConfigKey.ConfigKey_SaleNum])
            item:SetMaxBuyCount(maxBuyCount)
            --region 一次领取道具列表
            local strOneTime = cfgv[ConfigKey.ConfigKey_DirectAssetList] --格式：1111111,3|...
            local lstOneTime = GiftPackShopData.ItemString2List(strOneTime)
            local awardsImmediately = self:Lst2GiftPackShopItemAward(lstOneTime)
            item:SetAwardsImmediately(awardsImmediately)
            --endregion
            --region 周期领取道具列表
            local strCycle = cfgv[ConfigKey.ConfigKey_CycleAcceptAssetList] --格式：1111111,3|...
            local lstCycle = GiftPackShopData.ItemString2List(strCycle)
            local awardsDaily = self:Lst2GiftPackShopItemAward(lstCycle)
            item:SetAwardsDaily(awardsDaily)
            --endregion
            local strShopGiftType = cfgv[ConfigKey.ConfigKey_ShopGiftType]
            item:SetIsMonthCard(tonumber(strShopGiftType) == ShopGiftType.SGT_MonthCard)
            item:SetBattlePassGift(tonumber(strShopGiftType) == ShopGiftType.SGT_BattlePassGift)
            item:SetRechargeGift(tonumber(strShopGiftType) == ShopGiftType.SGT_RechargeGift)
            item.isWeekCard = tonumber(strShopGiftType) == ShopGiftType.SGT_WeekCard
            if cfgv[ConfigKey.ConfigKey_AcceptUseFullLife] then
                item.duration = tonumber(cfgv[ConfigKey.ConfigKey_AcceptUseFullLife])
            else
                --服务器不下发就读本地配置
                item.duration = Cfg.cfg_shop_giftmarket_goods[id].AcceptUsefulLife or 0
            end
            self:UpdateByServerData_LevelGift(item, good, cfgv, cfgClient)

            local refreshMethod = tonumber(cfgv[ConfigKey.ConfigKey_RefreshMethod])
            item:SetCycleType(refreshMethod)
            local refreshInterval = tonumber(cfgv[ConfigKey.ConfigKey_RefreshInterval])
            item:SetCycleDayCount(refreshInterval)

            item:SetRefreshTime(good.deadline_time) --刷新时间
            local showEndTime = tonumber(cfgv[ConfigKey.ConfigKey_ShowEndTime])
            item:SetEndTime(showEndTime) --下架时间

            --region 原价 折后价
            -- local saleType = tonumber(cfgv[ConfigKey.ConfigKey_SaleType])
            local saleType = cfgClient.SaleType --服务器配置拿不到ConfigKey_SaleType，用客户端的字段
            if saleType == SpecialNum.NeedPayMoney then ---888表示货币
                item:SetType(GiftPackType.Currency)
                item:SetPriceIcon(nil)
                item:SetPriceItemId(nil)
                local goodPrice = goodPriceList[midasId]
                if goodPrice then
                    item._price = goodPrice.microprice / 1000000
                    item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
                else
                    if showEndTime == nil then
                        table.insert(productList, midasId)
                    else
                        if showEndTime > curTime then
                            table.insert(productList, midasId)
                        end
                    end
                end
            else
                local priceRawNotCash = tonumber(cfgv[ConfigKey.ConfigKey_RawPrice]) --非直购原价
                local priceNotCash = tonumber(cfgv[ConfigKey.ConfigKey_NowPrice]) --非直购折后价
                if saleType == SpecialNum.FreeGiftSaleType then ---0表示免费
                    item:SetType(GiftPackType.Free)
                    item:SetPriceIcon(nil)
                    item:SetPriceItemId(nil)
                else
                    if saleType == RoleAssetID.RoleAssetDiamond then --耀晶
                        item:SetType(GiftPackType.Yaojing)
                    elseif saleType == RoleAssetID.RoleAssetGlow then --光珀
                        item:SetType(GiftPackType.Guangpo)
                    else
                        item:SetType(GiftPackType.Item)
                    end
                    item:SetPriceIcon("toptoon_" .. saleType)
                    item:SetPriceItemId(saleType)
                end
                item._priceRaw = priceRawNotCash
                item._price = priceNotCash
            end
            item._discount = tonumber(cfgv[ConfigKey.ConfigKey_Discount])
            --endregion

            --region cfg_shop_giftmarket_goods
            item:SetName(StringTable.Get(cfgClient.Name))
            item:SetIcon(cfgClient.Icon)
            item:SetIconDetail(cfgClient.IconDetail)
            --endregion
            item.isSkin = cfgClient.IsSkin or false
            table.insert(self._goods, item)
        else
            Log.fatal("### no goods in cfgs. id = ", id)
        end
    end

    if productList and table.count(productList) > 0 then
        --这里改为拉取所有物品的价格而不是只拉取当前页签需要的物品的价格，
        --防止同时请求两个页签数据的时候，米大师拉取谷歌端价格接口有bug
        GameGlobal.GetModule(ShopModule):GetLocalPrice()
    end
    local newList = marketInfo.new_mark_goods
    if newList and table.count(newList) > 0 then
        for _, newItem in ipairs(newList) do
            for _, good in ipairs(self._goods) do
                if newItem == good:GetId() then
                    if good:IsBattlePassGift() then
                        -- false
                    elseif good:IsLevelGift() then
                        good:SetNew(not good:IsLevelGiftLock())
                    else
                        good:SetNew(true)
                    end
                end
            end
        end
    end
end

-- 更新 等级礼包
---@param item GiftPackShopItem
---@param good MonthGiftGoodsInfo
function GiftPackShopData:UpdateByServerData_LevelGift(item, good, cfgv, cfgClient)
    local strShopGiftType = cfgv[ConfigKey.ConfigKey_ShopGiftType]
    if tonumber(strShopGiftType) == ShopGiftType.SGT_LevelGift then
        item:SetLevelGift(true)

        -- 等级礼包 限购数量 必须为 1
        local saleNum = tonumber(cfgv[ConfigKey.ConfigKey_SaleNum])
        if saleNum ~= 1 then
            Log.exception(
                "GiftPackShopData:UpdateByServerData_LevelGift()",
                " [cfg_shop_giftmarket_goods]",
                " ID = ",
                good.gift_id,
                " Error: GiftType == 5 and SaleNum ~= 1"
            )
        end

        local levelLock = (good.gift_lock_status & GiftLockStatus.GLS_LevelLock) ~= 0
        local preLock = (good.gift_lock_status & GiftLockStatus.GLS_PreposeLock) ~= 0
        local buy = good.selled_num ~= 0
        item:SetLevelGiftLock(levelLock)
        local isShow = not preLock and not buy
        item:SetLevelGiftShow(isShow)
        item:SetLevelGiftLockLv(tonumber(cfgv[ConfigKey.ConfigKey_LevelCondition]))

        local free = cfgClient.SaleType == 0
        local red = isShow and not levelLock and free
        item:SetLevelGiftRed(red)
    end
end

-- 商品客户端排序 等级礼包
function GiftPackShopData:SortGoods_Client_LevelGift()
    local tb = {}
    local items = {}
    for i, v in ipairs(self._goods) do
        if v:IsLevelGift() and v:IsLevelGiftShow() and v:IsLevelGiftLock() then
            table.insert(items, v)
        end
    end

    for i, v in ipairs(self._goods) do
        if not v:IsLevelGift() or (v:IsLevelGiftShow() and not v:IsLevelGiftLock()) then
            table.insert(tb, v)
        end
    end
    if #items > 0 then
        table.appendArray(tb, items)
    end
    self._goods = tb
end

-- 商品客户端排序 战斗通行证
function GiftPackShopData:SortGoods_Client_BattlePass()
    local campaignType = ECampaignType.CAMPAIGN_TYPE_BATTLEPASS
    local cmptId = ECampaignBattlePassComponentID.ECAMPAIGN_BATTLEPASS_BUY_GIFT

    ---@type UIActivityCampaign
    self._campaign = UIActivityCampaign:New()
    -- 战斗通行证侧边栏入口在游戏进入主界面时会拉取活动数据
    -- UIMainLobbySideEnterLoader:SetData(info)
    self._campaign:LoadCampaignInfo_Local(campaignType, cmptId)

    --- @type BuyGiftComponentInfo
    local componentInfo = self._campaign:GetComponentInfo(cmptId)
    local buyState = componentInfo and componentInfo.m_buy_state or -1
    local toFirst = (buyState == 0)
    local toLast = (buyState == 1 or buyState == 2)

    Log.debug("GiftPackShopData:SortGoods_Client_BattlePass()", " toFirst = ", toFirst, " toLast = ", toLast)

    local tb = {}
    local items = {}
    for i, v in ipairs(self._goods) do
        if v:IsBattlePassGift() then
            table.insert(items, v)
        end
    end

    if #items > 0 and toFirst then
        table.appendArray(tb, items)
    end
    for i, v in ipairs(self._goods) do
        if not v:IsBattlePassGift() then
            table.insert(tb, v)
        end
    end
    if #items > 0 and toLast then
        table.appendArray(tb, items)
    end
    self._goods = tb
end

function GiftPackShopData:UpdateGoodsPrice()
    local goodPriceList = self._mPay:GetGoodPriceList()
    if goodPriceList and table.count(goodPriceList) > 0 then
        for i, item in ipairs(self._goods) do
            local midasId = item:GetMidasId()
            if not string.isnullorempty(midasId) and goodPriceList[midasId] then
                local goodPrice = goodPriceList[midasId]
                item._price = goodPrice.microprice / 1000000
                item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
            end
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateGiftPackItemPrice)
    else
        Log.fatal("### [Pay]no data in goodPriceList.")
    end
end

---@return table 元素{templateId = xxx, count = yy}
function GiftPackShopData.ItemString2List(itemStr)
    local lst = {}
    local a = string.split(itemStr, "|")
    for _, idcount in ipairs(a) do
        local strs = string.split(idcount, ",")
        local templateId = tonumber(strs[1])
        local count = tonumber(strs[2])
        table.insert(lst, {templateId = templateId, count = count})
    end
    return lst
end

function GiftPackShopData:Lst2GiftPackShopItemAward(lst)
    local items = {}
    for i, item in ipairs(lst) do
        local item = GiftPackShopItemAward:New(item.templateId, item.count)
        table.insert(items, item)
    end
    return items
end

---@return GiftPackShopItem[]
function GiftPackShopData:GetGoods()
    self:SortGoods_Client_LevelGift()
    self:SortGoods_Client_BattlePass()
    return self._goods
end

function GiftPackShopData:GetRechargeGiftGoods()
   self.rechargeGiftGoods = {}
   for index, value in ipairs(self._goods) do
        if value:GetRechargeGift() then 
            table.insert(self.rechargeGiftGoods,value)
        end 
   end
   return self.rechargeGiftGoods
end
---@return GiftPackShopItem
function GiftPackShopData:GetGoodBuyId(id)
    for index, good in ipairs(self._goods) do
        if good:GetId() == id then
            return good
        end
    end
end

---是否有new礼包
function GiftPackShopData:GetNew()
    for index, good in ipairs(self._goods) do
        if good:GetNew() then
            return true
        end
    end
    return false
end

--endregion

--region ShopPriceItem
---@field _priceRaw number
---@field _price number
---@field _discount number
---@class ShopPriceItem:Object
_class("ShopPriceItem", Object)
ShopPriceItem = ShopPriceItem

function ShopPriceItem:Constructor(id)
    self._priceIcon = "" --价格图标
    self._priceItemId = 0 --价格道具id
    self._priceRaw = 1 --非直购原价
    self._price = 0 --非直购折后价，0为【免费】
    self._discount = 0 --折扣
    self._priceWithCurrencySymbol = "" --带货币符号的商品价格（$60.0）
end

function ShopPriceItem:GetPriceIcon()
    return self._priceIcon
end

function ShopPriceItem:SetPriceIcon(priceIcon)
    self._priceIcon = priceIcon
end

function ShopPriceItem:GetPriceItemId()
    return self._priceItemId
end

function ShopPriceItem:SetPriceItemId(priceItemId)
    self._priceItemId = priceItemId
end

function ShopPriceItem:GetPrice()
    return self._price
end

function ShopPriceItem:GetPriceRaw()
    return self._priceRaw
end

---@return number, string
function ShopPriceItem:GetDiscount()
    if self._discount > 0 then
        local str = StringTable.Get("str_pay_discount_percent", self._discount)
        return self._discount, str
    end
    return nil, nil
end

function ShopPriceItem:GetPriceWithCurrencySymbol()
    return self._priceWithCurrencySymbol
end

function ShopPriceItem:SetPriceWithCurrencySymbol(priceWithCurrencySymbol)
    priceWithCurrencySymbol = RechargeShopItem.RemoveDot00(priceWithCurrencySymbol)
    self._priceWithCurrencySymbol = priceWithCurrencySymbol
end

--endregion

--region GiftPackShopItem 礼包商店Item类
---@class GiftPackShopItem:ShopPriceItem
---@field isSkin boolean 是否皮肤礼包
_class("GiftPackShopItem", ShopPriceItem)
GiftPackShopItem = GiftPackShopItem

function GiftPackShopItem:Constructor(id)
    GiftPackShopItem.super.Constructor(self, id)
    self._currencyGoodsType = MidasCurrencyGoodsType.MIDAS_CURRENCY_GOODS_TYPE_GIFT_PACK
    self._id = id --礼包ID
    self._type = GiftPackType.Item
    self._midasId = "" --米大师商品ID，可以为空，因为不是所有的礼包都会花费货币
    self._name = "" --商品名称
    self._refreshTime = 0 --刷新时间戳
    self._endTime = 0 --剩余时间时间戳，一次性礼包的截止时间，周期性礼包和月卡的下次刷新时间；为0表示不显示剩余时间

    self._icon = "" --商品icon
    self._iconDetail = "" --商品详情icon
    self._buyCount = 0 --购买次数
    self._maxBuyCount = 0 --限购次数
    self._isMonthCard = false --是否月卡
    self._isBattlePassGift = false -- 是否是战斗通行证跳转入口
    self.isWeekCard = false --是否周卡
    self._cycleType = GiftPackCycleType.Once
    self._cycleDayCount = 0

    self._awardsImmediately = {}
    self._awardsDaily = {}

    self.duration = 0 --购买之后持续时长（天）

    self._new = false
end

function GiftPackShopItem:GetCurrencyGoodsType()
    return self._currencyGoodsType
end

function GiftPackShopItem:GetId()
    return self._id
end

---@return GiftPackType
function GiftPackShopItem:GetType()
    return self._type
end

function GiftPackShopItem:SetType(ptype)
    self._type = ptype
end

function GiftPackShopItem:GetMidasId()
    return self._midasId
end

function GiftPackShopItem:SetMidasId(midasId)
    self._midasId = midasId
    Log.debug("midasId : ", self._midasId)
end

function GiftPackShopItem:GetName()
    return self._name
end

function GiftPackShopItem:SetName(name)
    self._name = name
end

--region 刷新时间，剩余时间
function GiftPackShopItem:GetRefreshTime()
    return self._refreshTime
end

function GiftPackShopItem:SetRefreshTime(refreshTime)
    self._refreshTime = refreshTime
end

function GiftPackShopItem:GetEndTime()
    return self._endTime
end

function GiftPackShopItem:SetEndTime(endTime)
    self._endTime = endTime
end

--endregion

--是否月卡
function GiftPackShopItem:IsMonthCard()
    return self._isMonthCard
end

function GiftPackShopItem:SetIsMonthCard(isMonthCard)
    self._isMonthCard = isMonthCard
end

-- 是否是战斗通行证跳转入口
function GiftPackShopItem:IsBattlePassGift()
    return self._isBattlePassGift
end

function GiftPackShopItem:SetBattlePassGift(isBattlePassGift)
    self._isBattlePassGift = isBattlePassGift
end

function GiftPackShopItem:IsWeekCard()
    return self.isWeekCard
end

-- 是否是 等级礼包
function GiftPackShopItem:IsLevelGift()
    return self._isLevelGift
end

function GiftPackShopItem:SetLevelGift(isLevelGift)
    self._isLevelGift = isLevelGift
end

function GiftPackShopItem:IsLevelGiftShow()
    return self._isLevelGiftShow
end

function GiftPackShopItem:SetLevelGiftShow(isLevelGiftShow)
    self._isLevelGiftShow = isLevelGiftShow
end

function GiftPackShopItem:IsLevelGiftLock()
    return self._isLevelGiftLock
end

function GiftPackShopItem:SetLevelGiftLock(isLevelGiftLock)
    self._isLevelGiftLock = isLevelGiftLock
end

function GiftPackShopItem:SetLevelGiftLockLv(lv)
    self._isLevelGiftLockLv = lv
end

function GiftPackShopItem:GetLevelGiftLockLv()
    return self._isLevelGiftLockLv
end

function GiftPackShopItem:SetLevelGiftRed(red)
    self._isLevelGiftRed = red
end

function GiftPackShopItem:IsLevelGiftRed()
    return self._isLevelGiftRed
end

--刷新类型
---@return GiftPackCycleType
function GiftPackShopItem:GetCycleType()
    return self._cycleType
end

---@param refreshMethod number 说明：1按周刷新2按月刷新3周期刷新4一次性礼包
function GiftPackShopItem:SetCycleType(refreshMethod)
    if refreshMethod == 1 then
        self._cycleType = GiftPackCycleType.Weekly
    elseif refreshMethod == 2 then
        self._cycleType = GiftPackCycleType.Monthly
    elseif refreshMethod == 3 then
        self._cycleType = GiftPackCycleType.Cycle
    else
        self._cycleType = GiftPackCycleType.Once
    end
end

function GiftPackShopItem:GetCycleDayCount()
    return self._cycleDayCount
end

function GiftPackShopItem:SetCycleDayCount(cycleDayCount)
    self._cycleDayCount = cycleDayCount
end

function GiftPackShopItem.GetMonthCardMaxDayNum()
    local cfgv = Cfg.cfg_shop_global[1]
    if cfgv then
        local day = cfgv.MonthCardMaxDayNum
        return day
    end
    return 0
end

function GiftPackShopItem.GetMonthCycleDay()
    local cfgv = Cfg.cfg_shop_global[1]
    if cfgv then
        local day = cfgv.MonthCycleDay
        return day
    end
    return 0
end

--检查剩余天数
function GiftPackShopItem:CheckDayCount()
    local isMonthCard = self:IsMonthCard()
    if isMonthCard then
        local d, h, m, s = UICommonHelper.S2DHMS(self:GetRefreshTime())
        local dayCount = math.ceil(d)
        local monthCycleDay = GiftPackShopItem.GetMonthCycleDay()
        local monthCardMaxDayNum = GiftPackShopItem.GetMonthCardMaxDayNum()
        if dayCount + monthCycleDay > monthCardMaxDayNum then
            if self._type == GiftPackType.Currency then
                GameGlobal.GetUIModule(ShopModule):ReportPayStep(
                    PayStep.ClickPurchaseButton,
                    false,
                    -1,
                    "month_card_day_count_limit_reached"
                )
            end
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                "",
                StringTable.Get(
                    "str_pay_month_card_max_day_count_cant_over_limit",
                    GiftPackShopItem.GetMonthCardMaxDayNum()
                )
            )
            return false
        end
    else
        local nowTime = UICommonHelper.GetNowTimestamp()
        local endTime = self:GetEndTime()
        if nowTime > endTime then
            if self._type == GiftPackType.Currency then
                GameGlobal.GetUIModule(ShopModule):ReportPayStep(PayStep.ClickPurchaseButton, false, -1, "gift_invalid")
            end
            PopupManager.Alert(
                "UICommonMessageBox",
                PopupPriority.Normal,
                PopupMsgBoxType.Ok,
                "",
                StringTable.Get("str_pay_gift_invalid")
            )
            return false
        end
    end
    return true
end

---一次性礼包 -【 剩余N天/小时/分钟】；【已过期】-剩余时长为0时显示
---月卡 - 【尚未购买】当剩余领取天数为0时显示；【剩余领取N天】月卡剩余领取天数
---周期性礼包 - 【剩余N天/小时/分钟】；【已过期】-剩余时长为0时显示；
function GiftPackShopItem:GetCycleTypeStr()
    if self:IsMonthCard() then --月卡显示【尚未购买】或【剩余领取天数】
        local rt = self:GetRefreshTime()
        if rt <= 0 then
            return StringTable.Get("str_pay_not_buy_yet")
        else
            local d, h, m, s = UICommonHelper.S2DHMS(rt)
            local leftDays = math.ceil(d)
            return StringTable.Get("str_pay_left_collect_day", leftDays) --剩余领取N天
        end
    else
        local soldOut = self:HasSoldOut()
        if soldOut then --售罄不显示
            return
        end
        local endTime = self:GetEndTime()
        local mShop = GameGlobal.GetModule(ShopModule)
        local notShowLeftTime = mShop:GetClientShop():GetNotShowLeftTime()
        if endTime > notShowLeftTime then --超过配置时间不显示
            return
        end
        local leftSeconds = UICommonHelper.CalcLeftSeconds(endTime)
        if leftSeconds <= 0 then --已过期
            return StringTable.Get("str_pay_expired")
        end
        local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
        if d >= 1 then
            return StringTable.Get("str_pay_left_day", math.floor(d))
        else
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
end

---获取刷新时间字串
function GiftPackShopItem:GetRefreshTimeStr()
    if self:IsMonthCard() then --月卡不显示刷新时间
        return
    end
    local cycleType = self:GetCycleType()
    if cycleType == GiftPackCycleType.Once then --一次性礼包不显示刷新时间
        return
    end
    local refreshTime = self:GetRefreshTime()
    local leftSeconds = UICommonHelper.CalcLeftSeconds(refreshTime)
    if leftSeconds <= 0 then
        return
    end
    local d, h, m, s = UICommonHelper.S2DHMS(leftSeconds)
    if d >= 1 then
        return StringTable.Get("str_pay_purchase_refresh_n_day", math.floor(d))
    else
        if h >= 1 then
            return StringTable.Get("str_pay_purchase_refresh_n_hour", math.floor(h))
        else
            if m >= 1 then
                return StringTable.Get("str_pay_purchase_refresh_n_minute", math.floor(m))
            else
                return StringTable.Get("str_pay_purchase_refresh_n_minute", "<1")
            end
        end
    end
end

function GiftPackShopItem:GetIcon()
    return self._icon
end

function GiftPackShopItem:SetIcon(icon)
    self._icon = icon
end

function GiftPackShopItem:GetIconDetail()
    return self._iconDetail
end

function GiftPackShopItem:SetIconDetail(iconDetail)
    self._iconDetail = iconDetail
end

function GiftPackShopItem:GetBuyCount()
    return self._buyCount
end
function GiftPackShopItem:SetBuyCount(buyCount)
    self._buyCount = buyCount
end
function GiftPackShopItem:GetMaxBuyCount()
    return self._maxBuyCount
end
function GiftPackShopItem:SetMaxBuyCount(maxBuyCount)
    self._maxBuyCount = maxBuyCount
end

---是否售罄
function GiftPackShopItem:HasSoldOut()
    local buyCount = self:GetBuyCount()
    local maxBuyCount = self:GetMaxBuyCount()
    local soldOut = buyCount >= maxBuyCount
    return soldOut
end

function GiftPackShopItem:GetCountStr()
    if self:IsBattlePassGift() then
        return ""
    end
    local maxBuyCount = self:GetMaxBuyCount()
    if maxBuyCount == 888888888 then
        return ""
    end
    local buyCount = self:GetBuyCount()
    local n2m = (maxBuyCount - buyCount) .. "/" .. maxBuyCount
    local cycleType = self:GetCycleType()
    local strLimit = ""
    if cycleType == GiftPackCycleType.Weekly then
        strLimit = StringTable.Get("str_pay_purchase_limitation_weekly", n2m)
    elseif cycleType == GiftPackCycleType.Monthly then
        strLimit = StringTable.Get("str_pay_purchase_limitation_monthly", n2m)
    elseif cycleType == GiftPackCycleType.Cycle then
        local dayCount = self:GetCycleDayCount()
        strLimit = StringTable.Get("str_pay_purchase_limitation_n_day", dayCount, n2m)
    else
        strLimit = StringTable.Get("str_pay_purchase_limitation_forever", n2m)
    end
    return strLimit
end

---@return GiftPackShopItemAward[]
function GiftPackShopItem:GetAwardsImmediately()
    return self._awardsImmediately
end

function GiftPackShopItem:SetAwardsImmediately(awardsImmediately)
    self._awardsImmediately = awardsImmediately
end

---@return GiftPackShopItemAward[]
function GiftPackShopItem:GetAwardsDaily()
    return self._awardsDaily
end

function GiftPackShopItem:SetAwardsDaily(awardsDaily)
    self._awardsDaily = awardsDaily
end

function GiftPackShopItem:GetNew()
    return self._new
end

function GiftPackShopItem:SetNew(new)
    self._new = new
end

---@return boolean 是否皮肤礼包
function GiftPackShopItem:IsSkin()
    local cfgv = Cfg.cfg_shop_giftmarket_goods[self._id]
    if cfgv then
        return cfgv.IsSkin
    end
end

---@return boolean 是否显示在皮肤页签
function GiftPackShopItem:IsShowInSkinsTab()
    local cfgv = Cfg.cfg_shop_giftmarket_goods[self._id]
    if cfgv then
        return cfgv.ShowInSkinsTab
    end

    return false
end

---@return boolean 是否充值礼包
function GiftPackShopItem:SetRechargeGift(isRechargeGift)
    self._isRechargeGift = isRechargeGift
end

---@return boolean 是否充值礼包
function GiftPackShopItem:GetRechargeGift()
    return  self._isRechargeGift 
end
--endregion

---礼包类型
GiftPackType = {
    Currency = 0, --直购型
    Yaojing = 1, --耀晶型
    Guangpo = 2, --光珀型
    Item = 3, --道具型
    Free = 4 --免费型
}

---礼包刷新类型
GiftPackCycleType = {
    Once = 0, --一次性
    Monthly = 1, --月刷新
    Weekly = 2, --周刷新
    Cycle = 3 --周期刷新
}

--region GiftPackShopItemAward 礼包奖励类
---@class GiftPackShopItemAward:Object
_class("GiftPackShopItemAward", Object)
GiftPackShopItemAward = GiftPackShopItemAward

function GiftPackShopItemAward:Constructor(templateId, count)
    self._templateId = templateId
    self._count = count
    local cfg = Cfg.cfg_item[self._templateId]
    if cfg then
        self._name = StringTable.Get(cfg.Name)
        self._icon = cfg.Icon
    end
end

function GiftPackShopItemAward:GetTemplateId()
    return self._templateId
end

function GiftPackShopItemAward:GetIcon()
    return self._icon
end

function GiftPackShopItemAward:GetName()
    return self._name
end

function GiftPackShopItemAward:GetCount()
    return self._count
end

--endregion
