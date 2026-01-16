--[[
    商城:黑市商品数据基类
]]
---@class DShopSecretGoodBase
_class("DShopSecretGoodBase", Object)
DShopSecretGoodBase = DShopSecretGoodBase
function DShopSecretGoodBase:Constructor(goodinfo, goodconfig)
    self.discount = 0
end
---@class GoodInfo
function DShopSecretGoodBase:Refresh(goodinfo, goodconfig)
    self.goodId = goodinfo.goods_id -- 商品id
    self.cfg = goodconfig
    if goodconfig == nil then
        Log.error("err DShopSecretGoodBase  goodConfig is nil, goodsId = " .. self.goodId)
    end
    self.remainNum = self.cfg[ConfigKey.ConfigKey_SaleNum] - goodinfo.selled_num --已卖的数量
    self.discount = self.cfg and self.cfg[ConfigKey.ConfigKey_Discount] or 0
    self.saleMaxNum = self.cfg[ConfigKey.ConfigKey_SaleNum] --出售总数量
end
---@public
---商品唯一id
function DShopSecretGoodBase:GetGoodId()
    return self.goodId
end

---@public
---品剩余数量
function DShopSecretGoodBase:GetRemainCount()
    return self.remainNum
end

function DShopSecretGoodBase:GetDiscount()
    return self.discount
end

function DShopSecretGoodBase:GetSubTabType()
end
---@public
---商品总组数
function DShopSecretGoodBase:GetRemainTotalCount()
    return 1
end

---@public
---是否显示剩余数量
function DShopSecretGoodBase:ShowRemain()
    return false
end

---@public
---商品物品id
function DShopSecretGoodBase:GetItemId()
    return self.cfg and self.cfg[ConfigKey.ConfigKey_ItemId] or (self.localCfg and self.localCfg.ItemId or 0)
end

---@public
---是否是pet
function DShopSecretGoodBase:IsPet()
    local itemId = self:GetItemId()
    return Cfg.cfg_pet[itemId] ~= nil
end

---@public
---商品单次数量
function DShopSecretGoodBase:GetItemCount()
    return self.cfg and self.cfg[ConfigKey.ConfigKey_ItemCount] or (self.localCfg and self.localCfg.ItemCount or 0)
end

---@public
---售价货币类型
function DShopSecretGoodBase:GetSaleType()
    return self.cfg and self.cfg[ConfigKey.ConfigKey_SaleType] or (self.localCfg and self.localCfg.SaleType or 0)
end

---@public
---返回原始单价
function DShopSecretGoodBase:GetOriginalSalePrice()
    return self.cfg and self.cfg[ConfigKey.ConfigKey_RawPrice]
end

---@public
---折扣后销售价格
function DShopSecretGoodBase:GetSalePrice()
    local singlePrice = self:GetOriginalSalePrice()
    return self.cfg and self.cfg[ConfigKey.ConfigKey_NowPrice] or singlePrice
end

---@public
function DShopSecretGoodBase:GetSaleTag()
    return 0
end

---@public
function DShopSecretGoodBase:ShowSaleTag()
    return false
end

---是否是不限量商品
function DShopSecretGoodBase:IsUnLimit()
    return self.saleMaxNum == SpecialNum.MysteryGoodsUnlimitedNum
end
