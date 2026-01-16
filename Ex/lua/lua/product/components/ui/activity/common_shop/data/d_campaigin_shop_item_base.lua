--[[
    活动 兑换商城 商品ui数据结构
]]
---@class DCampaignShopItemBase
_class("DCampaignShopItemBase", Object)
---@class DCampaignShopItemBase:Object
function DCampaignShopItemBase:Constructor(goodsInfo)
end
---@param goodsInfo ExchangeItemComponentItemInfo
function DCampaignShopItemBase:Refresh(goodsInfo,exchangeCmpt)
    --self._baseGoodsInfo = goodsInfo
    self.goodsId = goodsInfo.m_id -- 商品id
    self.isSpecial = goodsInfo.m_is_special
    self.exchangeLimitCount = goodsInfo.m_exchange_limit_count
    self.remainNum = goodsInfo.m_can_exchange_count
    self.costCount = goodsInfo.m_cost_count
    self.costItemId = goodsInfo.m_cost_item_id
    self.unlockCostItems = goodsInfo.m_unlock_cost_item
    ---@type RoleAsset
    self.rewardInfo = {}
    self.rewardInfo.assetid = goodsInfo.m_reward.assetid
    self.rewardInfo.count = goodsInfo.m_reward.count
    self.exchangeCmpt = exchangeCmpt
end
---@public 
---商品唯一id
function DCampaignShopItemBase:GetGoodsId()
    return self.goodsId
end
---@public 
---是否是特殊商品
function DCampaignShopItemBase:GetIsSpecial()
    return self.isSpecial
end

---@public 
---商品剩余数量
function DCampaignShopItemBase:GetRemainCount()
    if self.exchangeLimitCount ~= -1 then
        return self.remainNum
    else   
        return -1
    end
end
function DCampaignShopItemBase:GetCostItemId()
    return self.costItemId
end
---@public 
---商品总组数
function DCampaignShopItemBase:GetRemainTotalCount()
    return 1
end

---@public 
---是否显示剩余数量
function DCampaignShopItemBase:ShowRemain()
    return self.exchangeLimitCount > 0
end

---@public 
---商品物品id
function DCampaignShopItemBase:GetItemId()
    return self.rewardInfo.assetid
end

---@public 
---是否是pet
function DCampaignShopItemBase:IsPet()
    local itemId = self:GetItemId()
    return Cfg.cfg_pet[itemId] ~= nil
end

---@public 
---商品单次数量
function DCampaignShopItemBase:GetItemCount()
    return self.rewardInfo.count
end

---@public 
---售价货币类型
function DCampaignShopItemBase:GetSaleType()
    return self.costItemId
end

---@public 
---折扣后销售价格
function DCampaignShopItemBase:GetSalePrice()
    return self.costCount
end

---@public
function DCampaignShopItemBase:GetSaleTag()
    return 0
end

---@public
function DCampaignShopItemBase:ShowSaleTag()
    return false
end

---是否是不限量商品
function DCampaignShopItemBase:IsUnLimit()
    return self.exchangeLimitCount <= 0
end

--商品解锁道具
function DCampaignShopItemBase:UnlockItems()
    return self.unlockCostItems
end

---------------------------------------------------

---@class DCampaignShopItemGroup
_class("DCampaignShopItemGroup", Object)
---@class DCampaignShopItemGroup:Object
function DCampaignShopItemGroup:Constructor()
    self._campaignId = 0
    self._unlockTime = 0
    self._showTime = 0
    self._closeTime = 0
    self._isShow = false
    self._isUnlock = false
    self._isClose = false
end