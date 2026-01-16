-- UIDrawCardPoolInfo 卡池数据
---@class UIDrawCardPoolInfo:Object
_class("UIDrawCardPoolInfo", Object)
UIDrawCardPoolInfo = UIDrawCardPoolInfo

---@param data PrizePoolInfo
function UIDrawCardPoolInfo:Constructor(data, idx)
    ---@type PrizePoolInfo
    self.poolData = data
    self.index = idx
    self.singleMat = nil --单抽材料物品id，不能单抽的卡池为nil
    self.singlePrice = nil --单抽价格
    self.singleOriPrice = nil --单抽原价
    self.singleDiscount = 0 --单抽折扣，没有折扣为nil
    self.multipleMat = nil --十连材料id
    self.multiplePrice = nil --十连价格
    self.multipleOriPrice = nil --十连原价
    self.multipleDiscount = 0 --十连折扣，没有折扣为nil

    self.freeCount = self.poolData.remain_free_count --单抽免费次数
    self.nextTimer = self.poolData.next_refresh_free_time --单抽免费次数下次刷新时间
    self.closeTimer = self.poolData.free_campaign_end_time --单抽免费次数刷新结束时间

    self.freeCount_Mul = self.poolData.mul_remain_free_count --十连免费次数
    self.nextTimer_Mul = self.poolData.mul_next_refresh_free_time --十连免费次数下次刷新时间
    self.closeTimer_Mul = self.poolData.mul_free_campaign_end_time --十连免费次数刷新结束时间

    ---@type RoleModule
    self._mRole = GameGlobal.GetModule(RoleModule)
    self.singleMat, self.singlePrice, self.singleOriPrice, self.singleDiscount = self:GetOneDrawInfo()
    self._canSingleDraw = self.singleMat ~= nil

    self.multipleMat, self.multiplePrice, self.multipleOriPrice, self.multipleDiscount = self:GetTenDrawInfo()
end

--返回单抽的材料id，价格，原价，折扣（百分比）
--使用材料优先级：免费单抽>专属单抽券>限时（特招）星标>星标/特招星标>耀晶兑换
function UIDrawCardPoolInfo:GetOneDrawInfo()
    local itemM = GameGlobal.GetModule(ItemModule)
    local canUseCoupon = false --单抽除了用材料1或材料2之外，可能会使用单抽券，而且默认1张抽卡券对应1次单抽，不可更改
    if self.poolData.pre_use_ticket and self.poolData.pre_use_ticket > 0 then
        canUseCoupon = itemM:GetItemCount(self.poolData.pre_use_ticket) > 0
    end
    if canUseCoupon then
        --单抽专属抽卡券，必定是1个券抽1次
        return self.poolData.pre_use_ticket, 1, 1, nil
    end

    if self.poolData.cost1_id == 0 and self.poolData.cost2_id == 0 then
        Log.exception("严重错误，卡池无材料消耗:", self.poolData.prize_pool_id)
    end
    local mats = {}
    if self:ItemCanOneDraw(self.poolData.cost1_id) then
        mats[#mats + 1] = {
            self.poolData.cost1_id,
            self.poolData.one_shake_price1,
            self.poolData.one_shake_discount1_price
        }
    end
    if self:ItemCanOneDraw(self.poolData.cost2_id) then
        mats[#mats + 1] = {
            self.poolData.cost2_id,
            self.poolData.one_shake_price2,
            self.poolData.one_shake_discount2_price
        }
    end
    if #mats == 0 then
        Log.error("没有可用的单抽材料:", self.poolData.prize_pool_id)
        return
    end
    for idx, data in ipairs(mats) do
        local id = data[1]
        local oriPrice = data[2]
        local discountPrice = data[3]
        local itemID = nil
        local cfg = Cfg.cfg_item[id]
        if id == RoleAssetID.RoleAssetDrawCard100 then
            --使用星标，判断能不能使用限时星标
            local item = itemM:GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempDrawTicket)
            if item then
                --有可用的限时星标
                itemID = item:GetTemplateID()
            else
                itemID = RoleAssetID.RoleAssetDrawCard100
            end
        elseif id == RoleAssetID.RoleAssetDrawCard101 then
            --使用特招星标
            local item = itemM:GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempSpecialTicket)
            if item then
                --有可用的限时特招星标
                itemID = item:GetTemplateID()
            else
                itemID = RoleAssetID.RoleAssetDrawCard101
            end
        else
            itemID = id
        end
        local have = itemM:GetItemCount(itemID)
        local price = oriPrice
        local discount = nil
        if discountPrice and discountPrice > 0 then
            price = discountPrice
            discount = math.ceil((oriPrice - discountPrice) / oriPrice * 100)
        end
        if have >= price then
            return itemID, price, oriPrice, discount
        elseif idx == #mats then
            --没有足够的，使用最后1个
            return itemID, price, oriPrice, discount
        end
    end
end

function UIDrawCardPoolInfo:GetTenDrawInfo()
    local itemM = GameGlobal.GetModule(ItemModule)
    if self.poolData.cost1_id == 0 and self.poolData.cost2_id == 0 then
        Log.exception("严重错误，卡池无材料消耗:", self.poolData.prize_pool_id)
    end
    local mats = {}
    if self:ItemCanTenDraw(self.poolData.cost1_id) then
        mats[#mats + 1] = {
            self.poolData.cost1_id,
            self.poolData.multiple_shake_price1,
            self.poolData.multiple_shake_discount1_price
        }
    end
    if self:ItemCanTenDraw(self.poolData.cost2_id) then
        mats[#mats + 1] = {
            self.poolData.cost2_id,
            self.poolData.multiple_shake_price2,
            self.poolData.multiple_shake_discount2_price
        }
    end
    if #mats == 0 then
        Log.exception("严重错误，没有可用的十连材料:", self.poolData.prize_pool_id)
    end
    for idx, data in ipairs(mats) do
        local id = data[1]
        local oriPrice = data[2]
        local discountPrice = data[3]

        local have = itemM:GetItemCount(id)
        local price = oriPrice
        local discount = nil
        if discountPrice and discountPrice > 0 then
            price = discountPrice
            discount = math.ceil((oriPrice - discountPrice) / oriPrice * 100)
        end
        if have >= price then
            return id, price, oriPrice, discount
        elseif idx == #mats then
            --没有足够的，使用最后1个
            return id, price, oriPrice, discount
        end
    end
end

--物品是否可用于单抽
function UIDrawCardPoolInfo:ItemCanOneDraw(id)
    if id and id > 0 then
        local cfg = Cfg.cfg_item[id]
        return cfg.ItemSubType ~= ItemSubType.ItemSubType_10DrawCardTicket --十连券，不能用于单抽
    end
    return false
end

--物品是否可用于十连抽
function UIDrawCardPoolInfo:ItemCanTenDraw(id)
    if id and id > 0 then
        return true
    end
    return false
end

function UIDrawCardPoolInfo:CloseTimer_Single()
    return self.closeTimer
end

function UIDrawCardPoolInfo:NextTimer_Single()
    return self.nextTimer
end

function UIDrawCardPoolInfo:GetFreeCount_Single()
    return self.freeCount
end

function UIDrawCardPoolInfo:CloseTimer_Multi()
    return self.closeTimer_Mul
end

function UIDrawCardPoolInfo:NextTimer_Multi()
    return self.nextTimer_Mul
end

function UIDrawCardPoolInfo:GetFreeCount_Multi()
    return self.freeCount_Mul
end

--region AssetId
-- 星标 3000100 光珀 3000003
-- 如果有cost2_id，则cost1_id=星标，cost2_id=光珀；
-- 如果没cost2_id，则cost1_id=光珀，cost2_id=0
---获取2种抽卡资源Id
function UIDrawCardPoolInfo:Get2AssetId()
    return self.poolData.cost1_id, self.poolData.cost2_id
end

--endregion

---@param xbId number 星标id
function UIDrawCardPoolInfo:GetXBName(isSingle)
    local costMat
    if isSingle then
        costMat = self.singleMat
    else
        costMat = self.multipleMat
    end
    local name = StringTable.Get("str_item_" .. costMat)
    return name
end

---是否花星标/特召星标抽卡
---@return boolean, number
function UIDrawCardPoolInfo:IsCostXB(isSingle)
    local costid
    if isSingle then
        costid = self.singleMat
    else
        costid = self.multipleMat
    end
    local isCostXB = costid == RoleAssetID.RoleAssetDrawCard100
    local isCostTZXB = costid == RoleAssetID.RoleAssetDrawCard101
    return isCostXB or isCostTZXB, costid
end

function UIDrawCardPoolInfo:GetPoolViewID()
    return self.poolData.performance_id
end

function UIDrawCardPoolInfo:IsCostGp(isSingle)
    local costid
    if isSingle then
        costid = self.singleMat
    else
        costid = self.multipleMat
    end
    return costid == RoleAssetID.RoleAssetGlow, costid
end

---获取资源价格，考虑折扣
---@param isSingle boolean 是否单抽
---@return number, number, number 原价，折扣价，折扣,用的材料id
function UIDrawCardPoolInfo:GetAssetsPrice(isSingle)
    if isSingle then
        return self.singleOriPrice, self.singlePrice, self.singleDiscount, self.singleMat
    else
        return self.multipleOriPrice, self.multiplePrice, self.multipleDiscount, self.multipleMat
    end
end

--region IsEnough 判断资源是否充足
---@return boolean, number 是否充足，差额
function UIDrawCardPoolInfo:IsXBEnough(cost, isSingle) --星标或特召星标
    local isCostXB, xbId = self:IsCostXB(isSingle)
    if not isCostXB then
        Log.fatal("### not cost xb.")
        return
    end
    local count = self._mRole:GetAssetCount(xbId)
    local isEnough = cost <= count
    local diff = cost - count
    return isEnough, diff
end

---@return boolean, number 是否充足，差额
function UIDrawCardPoolInfo:IsGPEnough(cost) --光珀
    local count = self._mRole:GetGlow()
    local isEnough = cost <= count
    local diff = cost - count
    return isEnough, diff
end

---@return boolean, number 是否充足，差额
function UIDrawCardPoolInfo:IsYJEnough(cost) --耀晶
    local mShop = GameGlobal.GetModule(ShopModule)
    local count, countFree = mShop:GetDiamondCount()
    local total = count
    local isEnough = cost <= total
    local diff = cost - total
    return isEnough, diff
end

--是否有免费抽卡次数（单抽或十连）
function UIDrawCardPoolInfo:HasFreeDraw()
    return self.freeCount > 0 or self.freeCount_Mul > 0
end

--卡池顶条物品
function UIDrawCardPoolInfo:GetTopTips()
    local viewID = self.poolData.performance_id
    local cfg = Cfg.cfg_drawcard_pool_view[viewID]
    if cfg == nil then
        Log.exception("cfg_drawcard_pool_view中缺少配置,卡池id:", self.poolData.prize_pool_id, ",表现id:",
            viewID)
    end

    local limitItem = {} --限时抽卡券
    if
        self.poolData.cost1_id == RoleAssetID.RoleAssetDrawCard100 or
        self.poolData.cost2_id == RoleAssetID.RoleAssetDrawCard100
    then
        --限时星标
        local item =
            GameGlobal.GetModule(ItemModule):GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempDrawTicket)
        if item then
            limitItem[#limitItem + 1] = item:GetTemplateID()
        end
    elseif
        self.poolData.cost1_id == RoleAssetID.RoleAssetDrawCard101 or
        self.poolData.cost2_id == RoleAssetID.RoleAssetDrawCard101
    then
        --限时特招星标
        local item =
            GameGlobal.GetModule(ItemModule):GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempSpecialTicket)
        if item then
            limitItem[#limitItem + 1] = item:GetTemplateID()
        end
    end
    if #limitItem > 0 then
        for _, id in ipairs(cfg.TopTips) do
            limitItem[#limitItem + 1] = id
        end
        return limitItem
    end
    return cfg.TopTips
end

---@return bool 这个卡池是否可以单抽
function UIDrawCardPoolInfo:CanSingleDraw()
    return self._canSingleDraw
end

--返回1个最近的需要刷新界面的时间
--单个卡池需要刷新界面的时间有：限时卡池结束、免费单抽次数刷新、免费十连次数刷新、限时（特招）星标结束
--如果有多个时间，返回1个最近的
---@return number 时间戳,秒
function UIDrawCardPoolInfo:GetRefreshTime()
    local poolCloseTime = nil --卡池结束时间
    local sinFreeRefreshTime = nil --免费单抽次数刷新时间
    local mulFreeRefreshTime = nil --免费十连次数刷新时间
    local xingBiaoCloseTime = nil --限时（特招）星标失效时间

    if self.poolData.close_type == PrizePoolOpenCloseType.TIME_CONDITON then
        poolCloseTime = self.poolData.extend_data
    elseif self.poolData.close_type == PrizePoolOpenCloseType.PLAY_TIMES_CONDITON and self.poolData.close_condition2 > 0 then
        --按次数或时间结束的卡池
        poolCloseTime = self.poolData.close_condition2
    end

    local now = GetSvrTimeNow()

    local sinCloseTime = self:CloseTimer_Single()
    if now <= sinCloseTime then
        --如果下次间隔时间比结束时间小
        local time = self:NextTimer_Single()
        if time > 0 then --下一次不再刷新的时候，服务器会返回0，有免费单抽未开始和已刷完最后1次两种情况
            sinFreeRefreshTime = time
        end
    end

    local mulCloseTime = self:CloseTimer_Multi()
    if now <= mulCloseTime then
        --如果下次间隔时间比结束时间小
        local time = self:NextTimer_Multi()
        if time > 0 then --下一次不再刷新的时候，服务器会返回0，有免费单抽未开始和已刷完最后1次两种情况
            mulFreeRefreshTime = time
        end
    end

    local itemM = GameGlobal.GetModule(ItemModule)
    local item = itemM:GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempDrawTicket)
    if not item then --限时星标和限时特招星标只会有1个
        item = itemM:GetAvailableLimitDrawcardCoupon(ItemSubType.ItemSubType_TempSpecialTicket)
    end
    if item then
        xingBiaoCloseTime =
            GameGlobal.GetModule(LoginModule):GetTimeStampByTimeStr(
                item:GetTemplate().CompulsiveDeadTime,
                Enum_DateTimeZoneType.E_ZoneType_GMT
            )
    end

    local timeTb = { poolCloseTime, sinFreeRefreshTime, mulFreeRefreshTime, xingBiaoCloseTime }
    if not next(timeTb) then
        return
    end

    local time = math.maxinteger
    for _, value in pairs(timeTb) do
        if value < time then
            time = value
        end
    end
    return time
end
