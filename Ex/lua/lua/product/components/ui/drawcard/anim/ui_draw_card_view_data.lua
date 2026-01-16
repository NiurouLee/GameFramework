---@class UIDrawCardViewData:Object 抽卡表现需要用的数据
_class("UIDrawCardViewData", Object)
UIDrawCardViewData = UIDrawCardViewData

---@param cards table<number,RoleAsset>
---@param duplicateTag table<number,number>
---@param type ShakeType
function UIDrawCardViewData:Constructor(cards, duplicateTag, type, poolID, fixed_reward)
    self._cards = cards
    self._shakeType = type
    self._poolID = poolID
    self._fixedReward = fixed_reward

    self._petNewTab = {}
    self._star = {}

    self._items = {}

    local items = {}
    local star = 0
    local maxStarId = 0
    local module = GameGlobal.GetModule(PetModule)
    --处理多抽星灵重复转化成材料
    if self._shakeType == ShakeType.SHAKE_MULTIPLE then
        for idx, value in ipairs(cards) do
            local cfg = Cfg.cfg_pet[value.assetid]
            if cfg.Star > star then
                star = cfg.Star
                maxStarId = value.assetid
            end
            self._star[idx] = cfg.Star

            local isDuplicate = duplicateTag[idx] == PET_RESULT_CODE.PET_ADD_EXP_ONLY
            if isDuplicate then
                for i = 1, #cfg.ExchangeItem do
                    local val = string.split(cfg.ExchangeItem[i], ",")
                    local id = tonumber(val[1])
                    local count = tonumber(val[2])

                    if items[id] then
                        items[id].count = items[id].count + count
                    else
                        local asset = RoleAsset:New()
                        asset.assetid = id
                        asset.count = count
                        items[id] = asset
                    end
                end
                --处理红票
                local coinCfg = Cfg.cfg_pet_coin { PetID = value.assetid }
                if coinCfg and #coinCfg > 0 then
                    coinCfg = coinCfg[1]
                    local pet = module:GetPetByTemplateId(value.assetid)
                    local times = pet:RepeatGetTimes()
                    if coinCfg.CoinRewardCount then
                        times = math.min(times, #coinCfg.CoinRewardCount)
                        local id = coinCfg.CoinID
                        local count = coinCfg.CoinRewardCount[times]
                        if items[id] then
                            items[id].count = items[id].count + count
                        else
                            local asset = RoleAsset:New()
                            asset.assetid = id
                            asset.count = count
                            items[id] = asset
                        end
                    end
                end
            end
            self._petNewTab[idx] = not isDuplicate
            Log.fatal(
                "多抽结果：" .. "[" .. idx .. "]:id->",
                value.assetid .. "，" .. cfg.Star .. "星" .. "，新获得：",
                not isDuplicate
            )
        end
        local idx = 1
        for key, value in pairs(items) do
            self._items[idx] = value
            idx = idx + 1
        end
    else
        local cfg = Cfg.cfg_pet[cards[1].assetid]
        star = cfg.Star
        maxStarId = cards[1].assetid
        local isDuplicate = duplicateTag[1] == PET_RESULT_CODE.PET_ADD_EXP_ONLY
        self._petNewTab[1] = not isDuplicate

        Log.fatal("单抽结果：" .. "[" .. 1 .. "]:id->", cfg.ID .. "，" .. star .. "星" .. "，新获得：",
            not isDuplicate)
        self._star[1] = star
    end
    --心之石
    if self._fixedReward then
        if self._fixedReward[1] then
            local asset = {}
            asset.assetid = self._fixedReward[1].assetid
            asset.count = self._fixedReward[1].count
            asset.heartstone = true
            table.insert(self._items, 1, asset)
        end 
    end
    self._maxStar = star
    self.maxStarId = maxStarId
end

---@return ShakeType
function UIDrawCardViewData:GetShakeType()
    return self._shakeType
end

function UIDrawCardViewData:GetCards()
    return self._cards
end

function UIDrawCardViewData:GetItems()
    return self._items
end

function UIDrawCardViewData:GetPoolID()
    return self._poolID
end

function UIDrawCardViewData:GetMaxStar()
    return self._maxStar
end

function UIDrawCardViewData:GetMaxStarId()
    return self.maxStarId
end

function UIDrawCardViewData:IsNewPet(idx)
    return self._petNewTab[idx]
end

--获取不可跳过的卡牌列表
function UIDrawCardViewData:GetUnskipCards(start)
    start = start or 1
    local t = {}
    for i = start, #self._cards do
        local isNew = self:IsNewPet(i)
        local star = self._star[i]
        --6星或新获得
        --MSG20413	（QA_李鑫）抽卡系统QA_获得卡牌表现修改以及6星重复获得可跳过_2021.03.29	5	QA-待制作	靳策, 1951	04/08/2021
        --MSG68159	（QA_程烨飞）抽卡QA_抽卡操作简化_20230713（客户端）	5	QA-开发制作中	靳策, jince	07/18/2023	
        if star > 4 then --3、4星不管是不是新获得都可跳过
            if isNew --[[ or star == 6]] then
                t[#t + 1] = self._cards[i]
            end
        end
    end
    return t
end
