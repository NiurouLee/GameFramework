--[[
    商城:神秘页签 黑市
]]
require "d_shop_secret_store_base"
---@class DShopBlackStore
_class("DShopBlackStore", DShopSecretStoreBase)
---@class DShopBlackStore:Object
DShopBlackStore = DShopBlackStore
function DShopBlackStore:Constructor()
    -- Log.error("DShopBlackStore:Constructor")
    -- self.remainSecond = 0
    -- self.maxCount = 999
    -- self.costType = RoleAssetID.RoleAssetGlow
    -- self.refreshTime = {}
    -- self.today_refreshed_count = 0
end

-- function DShopBlackStore:SetRefreshInfo(shopLevelId)
--     local cfg = Cfg.cfg_shop_level[shopLevelId]
--     if cfg then
--         local a = string.split(cfg.RefreshPrice, "|")
--         self.maxCount = cfg.RefreshMax
--         self.costType = cfg.RefreshCostType
--         for index = 1, self.maxCount do
--             local count = index
--             local consume = tonumber(a[index] or a[#a])
--             self.refreshTime[count] = consume
--         end
--     end
-- end
---override
-- self.market_type = 0 --商店MarketType
-- self.today_refreshed_count = 0 --当天已经手动刷新的次数
-- ---@class marketinfo MarketInfo
-- function DShopBlackStore:SetData(marketinfo, goodsconfig)
--     -- Log.error("DShopBlackStore:SetData")
--     DShopSecretStoreBase.SetData(self, marketinfo, goodsconfig)
--     -- self.today_refreshed_count = marketinfo.today_refreshed_count or 0
--     -- self:SetRefreshInfo(marketinfo.cur_level_id)
-- end

-- function DShopBlackStore:SetRemainSecond(remainSecond)
--     self.remainSecond = remainSecond
-- end

-- function DShopBlackStore:GetRemainSecond()
--     return self.remainSecond
-- end

-- function DShopBlackStore:GetCurCount()
--     return self.today_refreshed_count
-- end

-- function DShopBlackStore:GetMaxCount()
--     return self.maxCount
-- end

-- function DShopBlackStore:GetCostType()
--     return self.costType
-- end
-- ---@public 刷新次数对应花费
-- function DShopBlackStore:GetConsume()
--     local count = self.today_refreshed_count + 1
--     if count > self.maxCount then
--         count = self.maxCount
--     end
--     return self.refreshTime[count]
-- end
