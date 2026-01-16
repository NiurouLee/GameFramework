--region RechargeShopData 充值商店数据类
---@class RechargeShopData:Object
_class("RechargeShopData", Object)
RechargeShopData = RechargeShopData

function RechargeShopData:Constructor()
    ---@type RechargeShopItem[]
    self._goods = {}
    self._mPay = GameGlobal.GetModule(PayModule)
end

---@param marketInfo MarketInfo
---@param cfgs ConfigKey[] k=goodsId;v=ConfigKey
function RechargeShopData:UpdateByServerData(marketInfo, cfgs)
    if not marketInfo then
        Log.fatal("### marketInfo nil.")
        return
    end
    local goodPriceList = self._mPay:GetGoodPriceList()
    local productList = {}
    self._goods = {}
    ---@type GoodsInfo[]
    local serGoods = marketInfo.goods
    for i, good in ipairs(serGoods) do
        local goodsId = good.goods_id
        local cfgv = cfgs[goodsId]
        if cfgv then
            local item = RechargeShopItem:New(goodsId)
            local cfg_shop_paymarket_goods_v = Cfg.cfg_shop_paymarket_goods[goodsId]
            local midasId = cfgv[ConfigKey.ConfigKey_MidasItemId]
            item:SetMidasId(midasId)
            local keyName = cfg_shop_paymarket_goods_v.Name
            item:SetName(StringTable.Get(keyName))
            local keyLabel = cfg_shop_paymarket_goods_v.Tag
            item:SetLabel(StringTable.Get(keyLabel))
            local icon = cfg_shop_paymarket_goods_v.Icon or ""
            item:SetIcon(icon)
            item:SetCount(tonumber(cfgv[ConfigKey.ConfigKey_ItemCount]))
            --价格
            if goodPriceList[midasId] then
                local price = goodPriceList[midasId].price --显示为类似$1.99
                item:SetPrice(price)
            else
                table.insert(productList, midasId)
            end
            table.insert(self._goods, item)
        else
            Log.fatal("### no goods in cfgs. goodsId = ", goodsId)
        end
    end
    if productList and table.count(productList) > 0 then
        --这里改为拉取所有物品的价格而不是只拉取当前页签需要的物品的价格，
        --防止同时请求两个页签数据的时候，米大师拉取谷歌端价格接口有bug
        GameGlobal.GetModule(ShopModule):GetLocalPrice()
    end
    self:UpdateGoodsPresent() --活动信息
end

---根据米大师传回来的数据更新耀晶价格
function RechargeShopData:UpdateGoodsPrice()
    local goodPriceList = self._mPay:GetGoodPriceList()
    if goodPriceList and table.count(goodPriceList) > 0 then
        for i, item in ipairs(self._goods) do
            local midasId = item:GetMidasId()
            if goodPriceList[midasId] then
                local price = goodPriceList[midasId].price --显示为类似$1.99
                item:SetPrice(price)
            end
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateRechargeItemPrice)
    end
end
---更新道具赠送值
function RechargeShopData:UpdateGoodsPresent()
    local presents = self._mPay:GetGoodPresents()
    if presents and table.count(presents) > 0 then
        for i, item in ipairs(self._goods) do
            local count = item:GetCount()
            local present = presents[count]
            if present then
                item:SetHasBuy(present.hasBuy)
                item:SetCountFree(present.send_num)
            else
                Log.fatal(
                    "### [Pay][GetInfo] no good present in Midas json. midasId=[" ..
                        item:GetMidasId() .. "] num=" .. count
                )
            end
        end
        GameGlobal.EventDispatcher():Dispatch(GameEventType.UpdateRechargeItemPresent)
    else
        self._mPay:GetInfo("mp")
    end
end

---@return RechargeShopItem[]
function RechargeShopData:GetGoods()
    return self._goods
end

---@return RechargeShopItem
function RechargeShopData:GetGoodBuyId(id)
    for index, good in ipairs(self._goods) do
        if good:GetId() == id then
            return good
        end
    end
end

--endregion

--region RechargeShopItem 充值商店Item类
---@class RechargeShopItem:Object
_class("RechargeShopItem", Object)
RechargeShopItem = RechargeShopItem

function RechargeShopItem:Constructor(goodsId)
    self._id = goodsId --商品ID
    self._midasId = "" --米大师商品ID
    self._name = "" --商品名称
    self._label = "" --商品label
    self._price = "" --商品价格（带货币符号如￥、$等）
    self._icon = "" --商品icon
    self._hasBuy = true --是否购买过，默认购买过，以使未成功拉取到活动信息时默认不显示首充信息
    self._count = 0 --有偿耀晶数
    self._countFree = 0 --免费耀晶数
end

function RechargeShopItem:GetId()
    return self._id
end

function RechargeShopItem:GetMidasId()
    return self._midasId
end
function RechargeShopItem:SetMidasId(midasId)
    self._midasId = midasId
end

function RechargeShopItem:GetName()
    return self._name
end
function RechargeShopItem:SetName(name)
    self._name = name
end

function RechargeShopItem:GetLabel()
    return self._label
end
function RechargeShopItem:SetLabel(label)
    self._label = label
end

function RechargeShopItem:GetPrice()
    return self._price
end
function RechargeShopItem:SetPrice(price)
    price = RechargeShopItem.RemoveDot00(price)
    self._price = price
end

function RechargeShopItem.RemoveDot00(str)
    local newStr, num = string.gsub(str, "%.00", "")
    return newStr
end

function RechargeShopItem:GetIcon()
    return self._icon
end
function RechargeShopItem:SetIcon(icon)
    self._icon = icon
end

function RechargeShopItem:GetHasBuy()
    return self._hasBuy
end
function RechargeShopItem:SetHasBuy(hasBuy)
    self._hasBuy = hasBuy
end

function RechargeShopItem:GetCount()
    return self._count
end
function RechargeShopItem:SetCount(count)
    self._count = count
end
function RechargeShopItem:GetCountFree()
    return self._countFree
end
function RechargeShopItem:SetCountFree(countFree)
    self._countFree = countFree
end
--endregion
