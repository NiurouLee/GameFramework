--region UIActivityPayData 活动中的直购数据类
---@class UIActivityPayData:Object
_class("UIActivityPayData", Object)
UIActivityPayData = UIActivityPayData

function UIActivityPayData:Constructor()
    ---@type UIActivityPayItem[]
    self._goods = {}
    self._goodPriceList = {} --商品价格字典
    self._mPay = GameGlobal.GetModule(PayModule)
end

---@param marketInfo map<int,SkinMarketGoodsInfo>
---@param cfgs ConfigKey[] k=id;v=ConfigKey
-- function UIActivityPayData:UpdateByServerData(marketInfo, cfgs)
--     if not marketInfo then
--         Log.fatal("### marketInfo nil.")
--         return
--     end
--     local mShop = GameGlobal.GetModule(ShopModule)
--     local notShowLeftTime = mShop:GetClientShop():GetNotShowLeftTime()
--     local goodPriceList = self._mPay:GetGoodPriceList()
--     ---@type UIActivityPayItem[]
--     self._goods = {}
--     local serGoods = marketInfo
--     local productList = {}
--     for i, good in pairs(serGoods) do
--         local id = good.goodid
--         local cfgv = cfgs[id]
--         local cfgClient = Cfg.cfg_shop_common_goods[id]
--         if cfgv and cfgClient then
--             local item = UIActivityPayItem:New(id)
--             local midasId = cfgv[ConfigKey.ConfigKey_MidasItemId]
--             --good.midasid
--             item:SetMidasId(midasId)
--             item:SetEndTime(good.endtime)
--             -- item:SetIsShowLeftTime(true)
--             if good.endtime > notShowLeftTime then --不显示剩余时间
--                 item:SetIsShowLeftTime(false)
--             else
--                 item:SetIsShowLeftTime(true)
--             end
--             --region 价格
--             -- local saleType = tonumber(cfgv[ConfigKey.ConfigKey_SaleType])
--             local saleType = good.saletype
--             local priceNotCash = good.price --非直购价格
--             if saleType == SpecialNum.NeedPayMoney then ---888表示货币
--                 item:SetType(SkinsPayType.Currency)
--                 item:SetPriceIcon(nil)
--                 item:SetPriceItemId(nil)
--                 local goodPrice = goodPriceList[midasId]
--                 if goodPrice then
--                     item:SetPrice(goodPrice.microprice / 1000000)
--                     item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
--                 else
--                     table.insert(productList, midasId)
--                 end
--             elseif saleType == RoleAssetID.RoleAssetDiamond then --耀晶
--                 item:SetType(SkinsPayType.Yaojing)
--                 item:SetPriceIcon("toptoon_" .. saleType)
--                 item:SetPriceItemId(saleType)
--                 item:SetPrice(priceNotCash)
--             elseif saleType == RoleAssetID.RoleAssetGlow then --光珀
--                 item:SetType(SkinsPayType.Guangpo)
--                 item:SetPriceIcon("toptoon_" .. saleType)
--                 item:SetPriceItemId(saleType)
--                 item:SetPrice(priceNotCash)
--             elseif saleType == SpecialNum.FreeGiftSaleType then ---0表示免费
--                 item:SetType(SkinsPayType.Free)
--                 item:SetPriceIcon(nil)
--                 item:SetPriceItemId(nil)
--                 item:SetPrice(priceNotCash)
--             else
--                 item:SetType(SkinsPayType.Item)
--                 item:SetPriceIcon("toptoon_" .. saleType)
--                 item:SetPriceItemId(saleType)
--                 item:SetPrice(priceNotCash)
--             end
--             --endregion
--             item:SetSkinId(good.skin_id)
--             table.insert(self._goods, item)
--         else
--             Log.fatal("### no goods in cfgs. id = ", id)
--         end
--     end
--     if productList and table.count(productList) > 0 then
--         self._mPay:GetLocalPrice(productList)
--     end
-- end

function UIActivityPayData:UpdateGoodsPrice()
    local goodPriceList = self._mPay:GetGoodPriceList()
    if goodPriceList and table.count(goodPriceList) > 0 then
        -- GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateSkinsItemPrice)
        for i, item in ipairs(self._goods) do
            local midasId = item:GetMidasId()
            if not string.isnullorempty(midasId) and goodPriceList[midasId] then
                local goodPrice = goodPriceList[midasId]
                item:SetPrice(goodPrice.microprice / 1000000)
                item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
            end
        end
    else
        Log.fatal("### UIActivityPayData:UpdateGoodsPrice() no data in goodPriceList.")
    end
end

---@return UIActivityPayItem[]
function UIActivityPayData:GetGoods()
    return self._goods
end

---@return UIActivityPayItem
function UIActivityPayData:GetGoodById(id)
    for index, good in ipairs(self._goods) do
        if good:GetId() == id then
            return good
        end
    end
end

function UIActivityPayData:IsEmpty()
    local svrTimeModule = GameGlobal.GetModule(SvrTimeModule)
    local curTime = math.floor(svrTimeModule:GetServerTime() * 0.001)
    for index, good in ipairs(self._goods) do
        local endTime = good:GetEndTime()
        if endTime > 0 and endTime < curTime then
        else
            return false
        end
    end
    return true
end
--endregion

--region UIActivityPayItem 活动中的直购 Item 类
---@class UIActivityPayItem:Object
_class("UIActivityPayItem", Object)
UIActivityPayItem = UIActivityPayItem

function UIActivityPayItem:Constructor(id)
    --pay_module 中区分礼包、时装
    self._currencyGoodsType = MidasCurrencyGoodsType.MIDAS_CURRENCY_GOODS_TYPE_CAMPAIGN

    self._goodsId = id --商品id
    self._skinId = 0
    self._type = SkinsPayType.Currency
    self._midasId = "" --米大师商品ID，可以为空，因为不是所有的礼包都会花费货币
    self._name = "" --商品名称
    self._endTime = 0 --剩余时间时间戳
    self._priceIcon = "" --价格图标
    self._priceItemId = 0 --价格道具id
    self._price = 0 --商品价格，为0显示【免费】
    self._priceWithCurrencySymbol = "" --带货币符号的商品价格（$60.0）
    self._icon = "" --商品icon
    self._iconDetail = "" --商品详情icon
    self._buyCount = 0 --购买次数
    self._maxBuyCount = 0 --限购次数
    self._isShowLeftTime = true --是否显示剩余时间
    self._petModule = GameGlobal.GetModule(PetModule)
end

function UIActivityPayItem:GetCurrencyGoodsType()
    return self._currencyGoodsType
end

function UIActivityPayItem:GetId()
    return self._goodsId
end

function UIActivityPayItem:GetMidasId()
    return self._midasId
end

function UIActivityPayItem:SetMidasId(midasId)
    self._midasId = midasId
    Log.debug("midasId : ", self._midasId)
end

function UIActivityPayItem:GetBuyCount()
    return 1
end

function UIActivityPayItem:GetSkinId()
    return self._skinId
end

function UIActivityPayItem:SetSkinId(skinId)
    self._skinId = skinId
end

---@return SkinsPayType
function UIActivityPayItem:GetType()
    return self._type
end

function UIActivityPayItem:SetType(ptype)
    self._type = ptype
end

--region 剩余时间
function UIActivityPayItem:GetIsShowLeftTime()
    return self._isShowLeftTime
end

function UIActivityPayItem:SetIsShowLeftTime(isShowLeftTime)
    self._isShowLeftTime = isShowLeftTime
end

function UIActivityPayItem:GetEndTime()
    return self._endTime
end

function UIActivityPayItem:SetEndTime(endTime)
    self._endTime = endTime
end

--计算剩余秒数
function UIActivityPayItem:GetLeftSeconds()
    local mSvrTime = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = mSvrTime:GetServerTime() / 1000 --当前时间戳
    local endTime = self:GetEndTime() --到期时间戳
    local leftSeconds = endTime - nowTime --到截止日的秒数
    return leftSeconds
end
--endregion

function UIActivityPayItem:GetRemainTimeStr()
    local str = ""

    local leftSeconds = self:GetLeftSeconds()
    local cycleType = self:GetCycleType()
    if leftSeconds <= 0 then --已过期
        str = StringTable.Get("str_pay_expired")
    elseif leftSeconds <= 60 then --剩余1分钟
        str = StringTable.Get("str_pay_left_minute", 1)
    elseif leftSeconds <= 3600 then --剩余N分钟
        local leftMinutes = math.ceil(leftSeconds / 60)
        str = StringTable.Get("str_pay_left_minute", leftMinutes)
    elseif leftSeconds <= 86400 then --剩余N小时
        local leftHours = math.ceil(leftSeconds / 3600)
        str = StringTable.Get("str_pay_left_hour", leftHours)
    else --剩余N天
        local leftDays = math.ceil(leftSeconds / 86400)
        str = StringTable.Get("str_pay_left_day", leftDays)
    end
    return str
end

function UIActivityPayItem:GetPriceIcon()
    return self._priceIcon
end

function UIActivityPayItem:SetPriceIcon(priceIcon)
    self._priceIcon = priceIcon
end

function UIActivityPayItem:GetPriceItemId()
    return self._priceItemId
end

function UIActivityPayItem:SetPriceItemId(priceItemId)
    self._priceItemId = priceItemId
end

function UIActivityPayItem:GetPrice()
    return self._price
end

function UIActivityPayItem:SetPrice(price)
    self._price = price
end

function UIActivityPayItem:GetPriceWithCurrencySymbol()
    return self._priceWithCurrencySymbol
end

function UIActivityPayItem:SetPriceWithCurrencySymbol(priceWithCurrencySymbol)
    priceWithCurrencySymbol = RechargeShopItem.RemoveDot00(priceWithCurrencySymbol)
    self._priceWithCurrencySymbol = priceWithCurrencySymbol
end

function UIActivityPayItem:SetName(name)
    self._name = name
end

---是否售罄
function UIActivityPayItem:HasSoldOut()
    --判断是否有该皮肤
    return self._petModule:HaveSkin(self._skinId)
end
--endregion
