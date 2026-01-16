--region SkinsShopData 时装商店数据类
---@class SkinsShopData:Object
_class("SkinsShopData", Object)
SkinsShopData = SkinsShopData

function SkinsShopData:Constructor()
    ---@type SkinsShopItem[]
    self._goods = {}
    self._goodPriceList = {} --商品价格字典
    self._mPay = GameGlobal.GetModule(PayModule)
end

---@param marketInfo map<int,SkinMarketGoodsInfo>
---@param cfgs ConfigKey[] k=id;v=ConfigKey
---@param newList number[] 新时装id列表
function SkinsShopData:UpdateByServerData(marketInfo, cfgs, newList)
    if not marketInfo then
        Log.fatal("### marketInfo nil.")
        return
    end
    local mShop = GameGlobal.GetModule(ShopModule)
    local notShowLeftTime = mShop:GetClientShop():GetNotShowLeftTime()
    local goodPriceList = self._mPay:GetGoodPriceList()
    ---@type SkinsShopItem[]
    self._goods = {}
    local serGoods = marketInfo
    local productList = {}
    for i, good in HelperProxy:GetInstance():pairsByKeys(serGoods) do
        local id = good.goodid
        local cfgv = cfgs[id]
        local cfgClient = Cfg.cfg_shop_common_goods[id]
        if cfgv and cfgClient then
            local item = SkinsShopItem:New(id)
            local midasId = cfgv[ConfigKey.ConfigKey_MidasItemId]
            item:SetMidasId(midasId)
            item:SetEndTime(good.endtime)
            if good.endtime > notShowLeftTime then --不显示剩余时间
                item:SetIsShowLeftTime(false)
            else
                item:SetIsShowLeftTime(true)
            end
            --region 原价 折后价
            local saleType = good.saletype
            local priceNotCash = good.price --非直购价格
            if saleType == SpecialNum.NeedPayMoney then ---888表示货币
                item:SetType(SkinsPayType.Currency)
                item:SetPriceIcon(nil)
                item:SetPriceItemId(nil)
                local goodPrice = goodPriceList[midasId]
                if goodPrice then
                    item._price = goodPrice.microprice / 1000000
                    item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
                else
                    table.insert(productList, midasId)
                end
            else
                local priceRawNotCash = tonumber(cfgv[ConfigKey.ConfigKey_RawPrice]) --非直购原价
                local priceNotCash = tonumber(cfgv[ConfigKey.ConfigKey_NowPrice]) --非直购折后价
                if saleType == SpecialNum.FreeGiftSaleType then ---0表示免费
                    item:SetType(SkinsPayType.Free)
                    item:SetPriceIcon(nil)
                    item:SetPriceItemId(nil)
                else
                    if saleType == RoleAssetID.RoleAssetDiamond then --耀晶
                        item:SetType(SkinsPayType.Yaojing)
                    elseif saleType == RoleAssetID.RoleAssetGlow then --光珀
                        item:SetType(SkinsPayType.Guangpo)
                    else
                        item:SetType(SkinsPayType.Item)
                    end
                    item:SetPriceIcon("toptoon_" .. saleType)
                    item:SetPriceItemId(saleType)
                end
                item._priceRaw = priceRawNotCash
                item._price = priceNotCash
            end
            local isSeniorSkin = cfgClient.Type == CommonShopType.CommonShopType_SeniorSkin
            item:SetSeniorSkinStatus(isSeniorSkin)
            if isSeniorSkin then
                item:SetSeniorSkinReviewStatus(cfgClient.Subtype == 1) --子类型1
            end
            item._discount = tonumber(cfgv[ConfigKey.ConfigKey_Discount])
            --endregion
            item:SetSkinId(good.skin_id)
            table.insert(self._goods, item)
        else
            Log.fatal("### no goods in cfgs. id = ", id)
        end
    end
    if productList and table.count(productList) > 0 then
        --这里改为拉取所有物品的价格而不是只拉取当前页签需要的物品的价格，
        --防止同时请求两个页签数据的时候，米大师拉取谷歌端价格接口bug导致价格不全
        GameGlobal.GetModule(ShopModule):GetLocalPrice()
    end
    if newList and table.count(newList) > 0 then
        for _, newItem in ipairs(newList) do
            for _, good in ipairs(self._goods) do
                if newItem == good:GetId() then
                    good:SetNew(true)
                end
            end
        end
    end
end
function SkinsShopData:UpdateGoodsPrice()
    local goodPriceList = self._mPay:GetGoodPriceList()
    if goodPriceList and table.count(goodPriceList) > 0 then
        for i, item in ipairs(self._goods) do
            local midasId = item:GetMidasId()
            if not string.isnullorempty(midasId) and goodPriceList[midasId] then
                local goodPrice = goodPriceList[midasId]
                --item:SetPrice(goodPrice.microprice / 1000000)
                item:SetPriceWithCurrencySymbol(goodPrice.price) --$1.99
            end
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateSkinsItemPrice)
    else
        Log.fatal("### [Pay][Skins]no data in goodPriceList.")
    end
end

---@return SkinsShopItem[]
function SkinsShopData:GetGoods()
    return self._goods
end

---@return SkinsShopItem
function SkinsShopData:GetGoodById(id)
    for index, good in ipairs(self._goods) do
        if good:GetId() == id then
            return good
        end
    end
end
function SkinsShopData:IsEmpty()
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

---是否有new礼包
function SkinsShopData:GetNew()
    for index, good in ipairs(self._goods) do
        if good:GetNew() then
            return true
        end
    end
    return false
end
--endregion

--region SkinsShopItem 时装商店Item类
---@class SkinsShopItem:ShopPriceItem
_class("SkinsShopItem", ShopPriceItem)
SkinsShopItem = SkinsShopItem

function SkinsShopItem:Constructor(id)
    SkinsShopItem.super.Constructor(self, id)
    --pay_module 中区分礼包、时装
    self._currencyGoodsType = MidasCurrencyGoodsType.MIDAS_CURRENCY_GOODS_TYPE_SKIN
    self._goodsId = id --商品id
    self._skinId = 0
    self._type = SkinsPayType.Currency
    self._midasId = "" --米大师商品ID，可以为空，因为不是所有的礼包都会花费货币
    self._name = "" --商品名称
    self._endTime = 0 --剩余时间时间戳

    self._icon = "" --商品icon
    self._iconDetail = "" --商品详情icon
    self._buyCount = 0 --购买次数
    self._maxBuyCount = 0 --限购次数
    self._isShowLeftTime = true --是否显示剩余时间
    self._petModule = GameGlobal.GetModule(PetModule)
    self._new = false
    --耀精购买的皮肤可以添加直购模式，其他
    ---@type SkinsShopItem
    self._binderSkinItemByRMB = nil
    self._isSeniorSkin = false
end
function SkinsShopItem:SetBinderSkin(item)
    self._binderSkinItemByRMB = item
end
function SkinsShopItem:GetBinderSkin()
    return self._binderSkinItemByRMB
end
function SkinsShopItem:GetCurrencyGoodsType()
    return self._currencyGoodsType
end

function SkinsShopItem:GetId()
    return self._goodsId
end

function SkinsShopItem:GetSkinId()
    return self._skinId
end
function SkinsShopItem:SetSkinId(skinId)
    self._skinId = skinId
end
---@return SkinsPayType
function SkinsShopItem:GetType()
    return self._type
end
function SkinsShopItem:SetType(ptype)
    self._type = ptype
end

function SkinsShopItem:GetMidasId()
    return self._midasId
end
function SkinsShopItem:SetMidasId(midasId)
    self._midasId = midasId
    Log.debug("midasId : ", self._midasId)
end

function SkinsShopItem:GetBuyCount()
    return 1
end

--region 剩余时间
function SkinsShopItem:GetIsShowLeftTime()
    return self._isShowLeftTime
end
function SkinsShopItem:SetIsShowLeftTime(isShowLeftTime)
    self._isShowLeftTime = isShowLeftTime
end
function SkinsShopItem:GetEndTime()
    return self._endTime
end
function SkinsShopItem:SetEndTime(endTime)
    self._endTime = endTime
end
--计算剩余秒数
function SkinsShopItem:GetLeftSeconds()
    local mSvrTime = GameGlobal.GetModule(SvrTimeModule)
    local nowTime = mSvrTime:GetServerTime() / 1000 --当前时间戳
    local endTime = self:GetEndTime() --到期时间戳
    local leftSeconds = endTime - nowTime --到截止日的秒数
    return leftSeconds
end
--endregion

function SkinsShopItem:GetRemainTimeStr()
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

---是否售罄
function SkinsShopItem:HasSoldOut()
    --判断是否有该皮肤
    return self._petModule:HaveSkin(self._skinId)
end

function SkinsShopItem:GetNew()
    return self._new
end
function SkinsShopItem:SetNew(new)
    self._new = new
end
--endregion

---礼包类型
SkinsPayType = {
    Currency = 0, --直购型
    Yaojing = 1, --耀晶型
    Guangpo = 2, --光珀型
    Item = 3, --道具型
    Free = 4 --免费型
}

--endregion

--设置是否是高级时装
function SkinsShopItem:SetSeniorSkinStatus(status)
    self._isSeniorSkin = status
end

function SkinsShopItem:IsSeniorSkin()
    return self._isSeniorSkin
end

function SkinsShopItem:IsResident()
    local goodsId = self:GetId()
    local cfgClient = Cfg.cfg_shop_common_goods[goodsId]
    if cfgClient ~= nil and cfgClient.IsResident then
        return true
    else
        return false
    end
end

--设置是否是复刻的高级时装
function SkinsShopItem:SetSeniorSkinReviewStatus(status)
    self._isSeniorSkinReview = status
end

function SkinsShopItem:IsSeniorSkinReview()
    return self._isSeniorSkinReview
end

--region SkinsShopItemContainer
---@class SkinsShopItemContainer:Object
---@field itemSkin SkinsShopItem 皮肤item
---@field itemGift GiftPackShopItem 礼包item
_class("SkinsShopItemContainer", Object)
SkinsShopItemContainer = SkinsShopItemContainer

function SkinsShopItemContainer:Constructor()
    self.itemSkin = nil
    self.itemGift = nil
end
--endregion
