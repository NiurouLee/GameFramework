--region BlackFightData
---@field activityCampaign UIActivityCampaign
---@field curDay number 当前第几天（0基）
---@field difficultyList BlackFightDifficultyData[] 难度信息列表
---@field itemId number 声望道具id
---@field curReputation number 当前声望，即每日最高声望之和
---@field reputations BlackFightReputationData[] 声望信息列表
---@field salutations BlackFightSalutationData[] 称号信息字典 k=声望值 v=BlackFightSalutationData
---@field curOverviewPaper number 当前缩略小报
---@field papers BlackFightPaperData[] 小报列表
---@field rounds table 今日各个难度的当前轮次和最大轮次 k=难度 v={当前轮次， 最大轮次}
---@class BlackFightData : Object
_class("BlackFightData", Object)
BlackFightData = BlackFightData

function BlackFightData:Constructor()
    self.activityCampaign = UIActivityCampaign:New()
end

function BlackFightData:RequestCampaign(TT)
    local res = AsyncRequestRes:New()
    res:SetSucc(true)
    if self.activityCampaign._type == -1 or self.activityCampaign._id == -1 then
        self.activityCampaign:LoadCampaignInfo(TT, res, ECampaignType.CAMPAIGN_TYPE_N7)
    else
        self.activityCampaign:ReLoadCampaignInfo_Force(TT, res)
    end
    self:InitBlackFight()
    self:InitReputation()
    self:InitRounds()
    return res
end

---@return CCampaingN7 N7 LocalProcess
function BlackFightData:GetLocalProcess()
    return self.activityCampaign:GetLocalProcess()
end

---@return BlackfistComponent 黑拳赛组件
function BlackFightData:GetComponentBlackFight()
    return self.activityCampaign:GetComponent(ECampaignN7ComponentID.ECAMPAIGN_N7_BLACKFIST)
end
---@return PersonProgressComponent 声望组件
function BlackFightData:GetComponentReputation()
    return self.activityCampaign:GetComponent(ECampaignN7ComponentID.ECAMPAIGN_N7_LINE_PRESTIGE)
end

---@return BlackfistComponentInfo 黑拳赛组件信息
function BlackFightData:GetComponentInfoBlackFight()
    return self.activityCampaign:GetComponentInfo(ECampaignN7ComponentID.ECAMPAIGN_N7_BLACKFIST)
end
---@return PersonProgressComponentInfo 声望组件信息
function BlackFightData:GetComponentInfoReputation()
    return self.activityCampaign:GetComponentInfo(ECampaignN7ComponentID.ECAMPAIGN_N7_LINE_PRESTIGE)
end

function BlackFightData:InitBlackFight()
    local cInfoBlackFight = self:GetComponentInfoBlackFight()
    if not cInfoBlackFight then
        return
    end
    self.curDay = cInfoBlackFight.cur_day_index
    ---@type BlackFightDifficultyData[]
    self.difficultyList = {}
    local todayScore = {}
    local scores = cInfoBlackFight.score_infos
    if scores and table.count(scores) > 0 then
        for day, map in pairs(scores) do
            if day == self.curDay then
                for diff, score in pairs(map) do
                    todayScore[diff] = score
                end
                break
            end
        end
    end
    for _, diff in pairs(BlackFightDifficulty) do
        local difficulty = BlackFightDifficultyData:New()
        difficulty.difficulty = diff
        difficulty.reputaion = todayScore[diff] or 0
        self.difficultyList[diff] = difficulty
    end
    self.curDifficulty = BlackFightDifficulty.Light
end
function BlackFightData:InitRounds()
    local day = self.curDay
    if day == nil then
        return
    end
    if day > self:GetMaxDay() then
        day = 1
    end
    self.rounds = {}
    for k, i in pairs(BlackFightDifficulty) do
        local count, max = self:GetDifficultyTypeLevels(i, day)
        self.rounds[i] = {count, max}
    end
end
---@return number 最大天数
function BlackFightData:GetMaxDay()
    local max = 0
    local cfg = Cfg.cfg_component_blackfist()
    for key, value in pairs(cfg) do
        if value.DayIndex > max then
            max = value.DayIndex
        end
    end
    return max
end

---@return number, number 当前轮次，最大轮次
function BlackFightData:GetDifficultyTypeLevels(difficultyType, dayIndex)
    local count, max = 0, 0
    local cfg = Cfg.cfg_component_blackfist()
    for key, value in pairs(cfg) do
        if value.Type == difficultyType and value.DayIndex == dayIndex then
            if self:ComparisonContent(value.OrderId, difficultyType) then
                count = count + 1
            end
            max = max + 1
        end
    end
    if max == 0 then
        max = 1
    end
    return count, max
end
function BlackFightData:ComparisonContent(orderId, difficultyType)
    local cInfoBlackFight = self:GetComponentInfoBlackFight()
    if not cInfoBlackFight then
        return
    end
    local id = cInfoBlackFight.order_ids[difficultyType]
    if id == nil then
        id = 0
    end
    if id == 0 then
        return false
    end
    if orderId <= id then
        return true
    end
    return false
end
function BlackFightData:InitReputation()
    local cInfoReputation = self:GetComponentInfoReputation()
    if not cInfoReputation then
        return
    end
    self.itemId = cInfoReputation.m_item_id
    self.curReputation = cInfoReputation.m_current_progress
    ---@type BlackFightReputationData[]
    self.reputations = {}
    local receiveds = cInfoReputation.m_received_progress
    local progresses = cInfoReputation.m_progress_rewards
    local special = cInfoReputation.m_special_rewards
    if progresses and table.count(progresses) > 0 then
        local zero = BlackFightReputationData:New()
        zero.gotState = BlackFightReputationState.Got
        table.insert(self.reputations, zero)
        for key, reward in pairs(progresses) do
            local rd = BlackFightReputationData:New()
            rd.reputation = key
            rd.awards = reward
            if special[key] then
                rd.isSpecial = true
            end
            local hasGot = false
            for i, v in ipairs(receiveds) do
                if key == v then
                    hasGot = true
                    break
                end
            end
            if self.curReputation >= key then
                if hasGot then
                    rd.gotState = BlackFightReputationState.Got
                else
                    rd.gotState = BlackFightReputationState.CanGet
                end
            else
                rd.gotState = nil
            end
            table.insert(self.reputations, rd)
        end
        table.sort(
            self.reputations,
            function(a, b)
                return a.reputation < b.reputation
            end
        )
    end
    self:InitSalutation()
    --小报
    ---@type BlackFightPaperOverviewData
    self.curOverviewPaper = nil
    ---@type BlackFightPaperData[]
    self.papers = {}
    local cfgPaper = Cfg.cfg_n7_black_fight_paper()
    for k, v in pairs(cfgPaper) do
        local paper = BlackFightPaperData:New()
        paper:Init(k)
        table.insert(self.papers, paper)
    end
    self:InitCurPaper()
end
function BlackFightData:InitSalutation()
    ---@type BlackFightSalutationData[]
    self.salutations = {}
    if self.reputations and table.count(self.reputations) > 0 then
        for index, v in ipairs(self.reputations) do
            local key = "str_n7_salutation_" .. v.reputation
            if StringTable.Has(key) then
                local sd = BlackFightSalutationData:New()
                sd.reputation = v.reputation
                sd.salutation = StringTable.Get(key)
                table.insert(self.salutations, sd)
            end
        end
    end
end
function BlackFightData:InitCurPaper()
    if self.papers then
        local len = table.count(self.papers)
        for i = len, 1, -1 do
            local paper = self.papers[i]
            if self.curReputation >= paper.unlockReputation then
                self.curOverviewPaper = BlackFightPaperOverviewData:New()
                self.curOverviewPaper:Init(paper.idx)
                return
            end
        end
    end
end

function BlackFightData:GetPaperByIdx(idx)
    if self.papers then
        for index, paper in ipairs(self.papers) do
            if paper.idx == idx then
                return paper
            end
        end
    end
end

---@return BlackFightSalutationData 获取当前称号信息
function BlackFightData:GetCurSalutation()
    if self.salutations then
        local len = table.count(self.salutations)
        for i = len, 1, -1 do
            local salutation = self.salutations[i]
            if self.curReputation >= salutation.reputation then
                return salutation
            end
        end
    end
end
---@return BlackFightSalutationData 根据声望值获取称号信息
function BlackFightData:GetSalutionByReputation(reputation)
    if self.salutations and table.count(self.salutations) > 0 then
        for index, v in ipairs(self.salutations) do
            if v.reputation == reputation then
                return v
            end
        end
    end
end

function BlackFightData:GetReputation() --获取累计声望，即每日最高声望之和
    return self.curReputation
end
---@return BlackFightDifficulty, number
function BlackFightData:GetTodayMaxReputation() --获取今日最高声望
    local diff, max = BlackFightDifficulty.Light, 0
    if self.difficultyList and table.count(self.difficultyList) > 0 then
        for i, difficulty in ipairs(self.difficultyList) do
            if max < difficulty.reputaion then
                diff = difficulty.difficulty
                max = difficulty.reputaion
            end
        end
    end
    return diff, max
end

function BlackFightData:ExistCanGetAwards()
    if self.reputations and table.count(self.reputations) > 0 then
        for index, v in ipairs(self.reputations) do
            if v.gotState == BlackFightReputationState.CanGet then
                return true
            end
        end
    end
    return false
end

---将所有CanGet的声望状态设置为Got
function BlackFightData:SetReputationsGot()
    if self.reputations and table.count(self.reputations) > 0 then
        for index, v in ipairs(self.reputations) do
            if v.gotState == BlackFightReputationState.CanGet then
                v.gotState = BlackFightReputationState.Got
            end
        end
    end
end
---@return number, number 当前轮次，最大轮次
function BlackFightData:GetRoundInfoByDifficulty(diff)
    if self.rounds and self.rounds[diff] then
        return self.rounds[diff][1], self.rounds[diff][2]
    end
end

---@return boolean, BlackFightPaperData
function BlackFightData:ExistNotReadPaper()
    if self.papers then
        for index, paper in ipairs(self.papers) do
            if not paper:HasRead() then
                return true, paper
            end
        end
    end
    return false, nil
end
function BlackFightData:ReadPaper(idx)
    if self.papers then
        for index, paper in ipairs(self.papers) do
            if paper.idx == idx then
                paper:Read()
                GameGlobal.EventDispatcher():Dispatch(GameEventType.BlackFistUpdatePaperRed)
                return
            end
        end
    end
end
--endregion

--region BlackFightReputationData 声望信息--------------------------------------------------
---@field reputation number
---@field awards RoleAsset[]
---@field isSpecial boolean
---@field gotState BlackFightReputationState
---@class BlackFightReputationData : Object
_class("BlackFightReputationData", Object)
BlackFightReputationData = BlackFightReputationData

function BlackFightReputationData:Constructor()
    self.reputation = 0 --声望值
    self.awards = {} --声望奖励
    self.isSpecial = false --是否大奖
    self.gotState = nil --获取状态
end

--- @class BlackFightReputationState
local BlackFightReputationState = {
    CanGet = 1, --可领取
    Got = 2 --已领取
}
_enum("BlackFightReputationState", BlackFightReputationState)
--endregion

--region BlackFightSalutationData 称号信息--------------------------------------------------
---@field reputation number
---@field salutation string
---@class BlackFightSalutationData : Object
_class("BlackFightSalutationData", Object)
BlackFightSalutationData = BlackFightSalutationData

function BlackFightSalutationData:Constructor()
    self.reputation = 0 --该称号所需声望值
    self.salutation = "" --称号文本
end
--endregion

--region BlackFightDifficultyData 难度信息--------------------------------------------------
---@field difficulty BlackFightDifficulty 难度
---@field reputaion number 该难度今日声望
---@class BlackFightDifficultyData : Object
_class("BlackFightDifficultyData", Object)
BlackFightDifficultyData = BlackFightDifficultyData

function BlackFightDifficultyData:Constructor()
    self.difficulty = BlackFightDifficulty.Light
    self.reputaion = 0
end

--- @class BlackFightDifficulty
local BlackFightDifficulty = {
    Light = 1, --轻量级
    Middle = 2, --中量级
    Heavy = 3 --重量级
}
_enum("BlackFightDifficulty", BlackFightDifficulty)
--endregion

--region BlackFightPaperData 小报信息--------------------------------------------------
---@class BlackFightPaperData : Object
_class("BlackFightPaperData", Object)
BlackFightPaperData = BlackFightPaperData

function BlackFightPaperData:Constructor()
    self.idx = 0 --小报期数
    self.unlockReputation = 0 --解锁所需声望值
    ---@type BlackFightPaperElement[]
    self.elementsL = {} --小报元素列表（左侧）
    self.elementsR = {} --小报元素列表（右侧）
end
function BlackFightPaperData:Init(idx)
    self.idx = idx
    local cfgv = Cfg.cfg_n7_black_fight_paper[idx]
    if not cfgv then
        Log.fatal("### no data in cfg_n7_black_fight_paper. ID=", idx)
        return
    end
    self.unlockReputation = cfgv.Reputation
    self.elementsL, self.elementsR = self:GetElements(cfgv, "PartsDetails")
    return cfgv
end
---@return BlackFightPaperElement[], BlackFightPaperElement[]
function BlackFightPaperData:GetElements(cfgv, tField)
    local elementsL = {}
    local elementsR = {}
    local parts = cfgv[tField]
    if not parts then
        Log.warn("### no [" .. tField .. "] in cfg_n7_black_fight_paper.")
        return
    end
    local areas = {"l", "r"}
    for _, a in ipairs(areas) do
        local es = parts[a]
        for i, element in ipairs(es) do
            local e = BlackFightPaperElement:New()
            e.type = element.type
            if element.t then
                e.pos.x, e.pos.y = element.t[1], element.t[2]
            end
            if element.r then
                e.rot = Quaternion:SetEuler(element.r[1], element.r[2], element.r[3])
            end
            if element.s then
                e.scale.x, e.scale.y = element.s[1], element.s[2]
            end
            if element.wh_text then
                e.whText.x, e.whText.y = element.wh_text[1], element.wh_text[2]
            end
            if element.wh_img then
                e.whImg.x, e.whImg.y = element.wh_img[1], element.wh_img[2]
            end
            e.name = element.name or ""
            e.text = element.text or ""
            if not string.isnullorempty(element.font) then
                e.font = element.font .. ".prefab"
            end
            if a == areas[1] then
                table.insert(elementsL, e)
            else
                table.insert(elementsR, e)
            end
        end
    end
    return elementsL, elementsR
end

---是否解锁
function BlackFightPaperData:IsUnlock()
    local mCampaign = GameGlobal.GetModule(CampaignModule)
    local data = mCampaign:GetN7BlackFightData()
    local unlock = data:GetReputation() >= self.unlockReputation
    return unlock
end
---是否已读
function BlackFightPaperData:HasRead()
    if self:IsUnlock() then
        return UnityEngine.PlayerPrefs.HasKey(BlackFightPaperData.GetPrefsKeyPaperUnlock(self.idx))
    end
    return true
end
function BlackFightPaperData:Read()
    if self:IsUnlock() then
        UnityEngine.PlayerPrefs.SetInt(BlackFightPaperData.GetPrefsKeyPaperUnlock(self.idx), 1)
    end
end
function BlackFightPaperData.GetPrefsKeyPaperUnlock(idx)
    return Summer1Data.GetPrefsKey("BlackFightPaperUnlock") .. idx
end
--endregion

--region BlackFightPaperData 小报缩略信息--------------------------------------------------
---@class BlackFightPaperOverviewData : Object
_class("BlackFightPaperOverviewData", Object)
BlackFightPaperOverviewData = BlackFightPaperOverviewData

function BlackFightPaperOverviewData:Constructor()
    self.idx = 0
    self.btnPos = Vector2.zero
end

function BlackFightPaperOverviewData:Init(idx)
    self.idx = idx
    local cfgv = Cfg.cfg_n7_black_fight_paper[idx]
    self.btnPos.x = cfgv.PartsOverview.btnPos[1]
    self.btnPos.y = cfgv.PartsOverview.btnPos[2]
end
--endregion

--region BlackFightPaperElement 小报元素--------------------------------------------------
---@class BlackFightPaperElement : Object
_class("BlackFightPaperElement", Object)
BlackFightPaperElement = BlackFightPaperElement

function BlackFightPaperElement:Constructor()
    self.type = BlackFightPaperElementType.Text
    self.pos = Vector2.zero --位置
    self.rot = Quaternion.identity --旋转
    self.scale = Vector2.one --缩放
    self.whText = Vector2.zero --文本宽高
    self.whImg = Vector2.zero --图片宽高
    self.name = "" --资源名
    self.text = "" --文本内容
    self.font = "" --字体
end

--- @class BlackFightPaperElementType
local BlackFightPaperElementType = {
    Empty = 0, --空白
    Text = 1, --纯文本
    RawImage = 2, --散图
    Image = 3, --图集精灵
    RawImageText = 4, --散图文本
    FloatRawImageText = 5 --浮动散图文本
}
_enum("BlackFightPaperElementType", BlackFightPaperElementType)
--endregion
