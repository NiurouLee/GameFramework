--[[
    商店兑换页签数据
]]
---@class ExchangeShopData:Object
_class("ExchangeShopData", Object)
ExchangeShopData = ExchangeShopData

function ExchangeShopData:Constructor()
    self._shopGoods = {
        [MarketType.Shop_XingZuan] = {},
        [MarketType.Shop_HuiYao] = {},
        [MarketType.Shop_GuangPo] = {},
        [MarketType.Shop_HongPiao] = {},
        [MarketType.Shop_Season] = {},
    }
    -- local xzCfgs = Cfg.cfg_shop_xingzuan_goods {}
    -- for _, cfg in pairs(xzCfgs) do
    --     self:AddGoods(MarketType.Shop_XingZuan, cfg)
    -- end
    -- local xzCfgs = Cfg.cfg_shop_huiyao_goods {}
    -- for _, cfg in pairs(xzCfgs) do
    --     self:AddGoods(MarketType.Shop_HuiYao, cfg)
    -- end
    -- local xzCfgs = Cfg.cfg_shop_guangpo_goods {}
    -- for _, cfg in pairs(xzCfgs) do
    --     self:AddGoods(MarketType.Shop_GuangPo, cfg)
    -- end
end

function ExchangeShopData:SetData()
end

function ExchangeShopData:GetGoods(shopType)
    return self._shopGoods[shopType]
end

function ExchangeShopData:AddGoods(shop, goodsInfo, cfg)
    -- local goods = GoodsInfo:New()
    -- goods.goods_id = cfg.ItemId
    -- goods.selled_num = 0
    local data = ExchangeShopGoods:New()

    data:Refresh(goodsInfo, cfg)
    table.insert(self._shopGoods[shop], data)
end

--切换页签成功会走这里，设置相关用到的数据
function ExchangeShopData:RefreshData(shop)
    ---@type ShopModule
    local module = GameGlobal.GetModule(ShopModule)
    ---@type MarketInfo
    local info
    local cfgs
    if shop == MarketType.Shop_XingZuan then
        info, cfgs, _ = module:GetXingzuanData()
        table.clear(self._shopGoods[MarketType.Shop_XingZuan])
    elseif shop == MarketType.Shop_HuiYao then
        info, cfgs, _ = module:GetHuiyaoData()
        table.clear(self._shopGoods[MarketType.Shop_HuiYao])
    elseif shop == MarketType.Shop_GuangPo then
        info, cfgs, _ = module:GetGlowData()
        table.clear(self._shopGoods[MarketType.Shop_GuangPo])
    elseif shop == MarketType.Shop_HongPiao then
        info, cfgs, _ = module:GetHongPiaoData()
        table.clear(self._shopGoods[MarketType.Shop_HongPiao])
    elseif shop == MarketType.Shop_Season then
        info, cfgs, _ = module:GetSeasonData()
        table.clear(self._shopGoods[MarketType.Shop_Season])
    end
    if info then
        for _, goods in pairs(info.goods) do
            local cfg = cfgs[goods.goods_id]
            self:AddGoods(shop, goods, cfg)
        end
    end

    ---@type SvrTimeModule
    local timeModule = GameGlobal.GetModule(SvrTimeModule)
    local now = math.floor(timeModule:GetServerTime() / 1000)
    self._refreshTime = now + module:GetExchangeRefreshTime()
end

--剩余刷新时间(秒)，可以每秒调用
function ExchangeShopData:RefreshTime()
    local timeModule = GameGlobal.GetModule(SvrTimeModule)
    return self._refreshTime - math.floor(timeModule:GetServerTime() / 1000)
end

---------------------------------------

--[[
    
]]
---@class ExchangeShopGoods:DShopSecretGoodBase
_class("ExchangeShopGoods", DShopSecretGoodBase)
ExchangeShopGoods = ExchangeShopGoods

function ExchangeShopGoods:ShowRemain()
    return true
end

function ExchangeShopGoods:IsUnLimit()
    return self.cfg[ConfigKey.ConfigKey_SaleNum] == SpecialNum.MysteryGoodsUnlimitedNum
end
