--[[
    活动 抽奖商店 商品ui数据结构
]]
---@class DCampaignDrawShopItem
_class("DCampaignDrawShopItem", Object)
---@class DCampaignDrawShopItem:Object
function DCampaignDrawShopItem:Constructor(goodsInfo)
end
---@param goodsInfo AwardInfo
function DCampaignDrawShopItem:Refresh(goodsInfo,component)
    self.award_id = goodsInfo.m_award_id 
    self.item_id = goodsInfo.m_item_id
    self.item_count = goodsInfo.m_count
    self.remain_num = goodsInfo.m_lottery_count
    self.lottery_limit_count = goodsInfo.m_lottery_limit_count
    self.is_big_reward = goodsInfo.m_is_big_reward
    ---@type LotteryComponent
    self.lotteryCmpt = component
end
---@public 
---剩余数量
function DCampaignDrawShopItem:GetRestNum()
    return self.remain_num
end
---@public 
---剩余数量
function DCampaignDrawShopItem:GetTotalNum()
    --temp
    return self.lottery_limit_count
end
---@public 
---物品id
function DCampaignDrawShopItem:GetItemId()
    return self.item_id
end
---@public 
---物品数量
function DCampaignDrawShopItem:GetItemCount()
    return self.item_count
end
---@public 
---是否是大奖
function DCampaignDrawShopItem:IsBigReward()
    return self.is_big_reward
end

----------------------------------------------------
--[[
    活动 抽奖商店 奖池ui数据结构
]]
---@class DCampaignDrawShopItemBox:Object
_class("DCampaignDrawShopItemBox", Object)
DCampaignDrawShopItemBox = DCampaignDrawShopItemBox

function DCampaignDrawShopItemBox:Constructor(goodsInfoList)
end
---@param goodsInfoList list<AwardInfo>
function DCampaignDrawShopItemBox:Refresh(goodsInfoList,component)
    ---@type LotteryComponent
    self.lotteryCmpt = component
    self.itemGroup = {}
    local boxItemLimit = 3
    local rowCellData = {}
    local curItemCountInRowCell = 0
    self:Sort(goodsInfoList)
    for index, value in ipairs(goodsInfoList) do
        local shopItem = DCampaignDrawShopItem:New()
        shopItem:Refresh(value,component)
        curItemCountInRowCell = curItemCountInRowCell + 1
        table.insert(rowCellData, shopItem)
        if curItemCountInRowCell == boxItemLimit or index == #goodsInfoList then
            table.insert(self.itemGroup, rowCellData)
            rowCellData = {}
            curItemCountInRowCell = 0
        end
    end
end
function DCampaignDrawShopItemBox:Sort(goodsInfoList)
    table.sort(goodsInfoList, 
    function(a, b)
        local ra = 1
        local rb = 1
        if a.m_lottery_count == 0 then
            ra = 0
        end
        if b.m_lottery_count == 0 then
            rb = 0
        end
        if ra ~= rb then
            return ra > rb
        end
        return a.m_award_id < b.m_award_id
    end)
end
function DCampaignDrawShopItemBox:GetTotalRestItem()
    local rest = 0
    local total = 0
    for index, value in ipairs(self.itemGroup) do
        for cellIndex, cellData in ipairs(value) do
            rest = rest + cellData:GetRestNum()
            total = total + cellData:GetTotalNum()
        end
    end
    return rest,total
end

function DCampaignDrawShopItemBox:SortBig(goodsInfoList)
    table.sort(goodsInfoList, 
    function(a, b)
        local ra = 1
        local rb = 1
        if a.m_is_big_reward or b.m_is_big_reward then
            if a.m_is_big_reward  then
                return true
            else 
                return false
            end 
        end
        if a.m_lottery_count == 0 then
            ra = 0
        end
        if b.m_lottery_count == 0 then
            rb = 0
        end
        if ra ~= rb then
            return ra > rb
        end
        return a.m_award_id < b.m_award_id
    end)
end

function DCampaignDrawShopItemBox:SortByRewardType(goodsInfoList)
    table.sort(goodsInfoList, 
    function(a, b)
        local ac = a.m_lottery_count ~= 0
        local bc = b.m_lottery_count ~= 0
        if ac ~= bc then
            return ac -- 优先显示未抽空的道具，其次显示已抽空的道具
        end
        if a.m_reward_type ~= b.m_reward_type then
            return a.m_reward_type > b.m_reward_type -- 上述同类型道具中优先显示大奖，其次显示小奖，再次显示无标签奖励
        end
        return a.m_award_id < b.m_award_id -- 上述同类型道具中按奖池配置顺序排序
    end)
end
----------------------------------------------------
--[[
    活动 抽奖商店 暂存抽奖结果结构
]]
---@class DCampaignDrawShopDrawResultRecord:Object
_class("DCampaignDrawShopDrawResultRecord", Object)
DCampaignDrawShopDrawResultRecord = DCampaignDrawShopDrawResultRecord

function DCampaignDrawShopDrawResultRecord:Constructor()
end
function DCampaignDrawShopDrawResultRecord:Record(getRewards,lotteryType,curBoxHasRest,isOpenNew,canDrawOnceMore)
    self.m_getRewards = getRewards
    self.m_lotteryType = lotteryType
    self.m_curBoxHasRest = curBoxHasRest
    self.m_isOpenNew = isOpenNew
    self.m_canDrawOnceMore = canDrawOnceMore
end
