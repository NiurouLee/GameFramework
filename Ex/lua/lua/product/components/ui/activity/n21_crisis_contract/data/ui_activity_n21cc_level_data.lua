local UIActivityN21CCLevelStatus = {
    None = 0,
    Lock = 1,
    Open = 2
}
---@class UIActivityN21CCLevelStatus:UIActivityN21CCLevelStatus
_enum("UIActivityN21CCLevelStatus", UIActivityN21CCLevelStatus)

_class("UIActivityN21CCLevelData", Object)
---@class UIActivityN21CCLevelData:Object
UIActivityN21CCLevelData = UIActivityN21CCLevelData

---@param missionComponentInfo ChallengeMissionComponentInfo
function UIActivityN21CCLevelData:Constructor(cfg, missionComponentInfo)
    ---@type ChallengeMissionComponentInfo
    self._missionComponentInfo = missionComponentInfo
    ---@type SvrTimeModule
    self._timeModule = GameGlobal.GetModule(SvrTimeModule)
    self._monsterIcon = cfg.MonsterIcon
    self._monsterIcon1 = cfg.MonsterIcon1
    if not self._monsterIcon1 then
        self._monsterIcon1= ""  
    end
    self._monsterName = StringTable.Get(cfg.MonsterName)
    self._recommendAwaken = cfg.RecommendAwaken
    self._recommendLV = cfg.RecommendLV
    self._missionId = cfg.CampaignMissionId
    self._levelIndex = cfg.LeveIndex
    self._hardId = cfg.HardID
    self._elementIcon1 = cfg.ElementIcon1
    self._elementIcon2 = cfg.ElementIcon2
    local cfgs = Cfg.cfg_campaign_mission {CampaignMissionId = self._missionId}
    if cfgs and #cfgs > 0 then
        local misionCfg = cfgs[1]
        self._fightId = misionCfg.FightLevel
        self._name = StringTable.Get(misionCfg.Name)
        self._des = StringTable.Get(misionCfg.Desc)
    end
    ---@type UIActivityN21CCAffixGroupsData[]
    self._affixGroups = {}
    local affixs = cfg.Affix
    for i = 1, #affixs do
        local selectIds = nil
        if self._missionComponentInfo.m_select_affix and self._missionComponentInfo.m_select_affix[self._missionId] then
            selectIds = self._missionComponentInfo.m_select_affix[self._missionId]
        end
        self._affixGroups[#self._affixGroups + 1] = UIActivityN21CCAffixGroupsData:New(affixs[i], selectIds)
    end
    self._unlockScore = cfg.UnlockScore
    self._baseScore = cfg.BaseScore
    self._status = UIActivityN21CCLevelStatus.None
    self:Refresh()
end

function UIActivityN21CCLevelData:Refresh()
    self._maxScore = 0
    if self._missionComponentInfo.m_max_score and self._missionComponentInfo.m_max_score[self._levelIndex] then
        self._maxScore = self._missionComponentInfo.m_max_score[self._levelIndex]
    end
    local unlockTime = 0
    if self._missionComponentInfo.m_challenge_unlock_time and self._missionComponentInfo.m_challenge_unlock_time[self._missionId] then
        unlockTime = self._missionComponentInfo.m_challenge_unlock_time[self._missionId]
    end
    local nowTime = self._timeModule:GetServerTime() / 1000
    if nowTime >= unlockTime and self._maxScore >= self._unlockScore then
        self._status = UIActivityN21CCLevelStatus.Open
    else
        self._status = UIActivityN21CCLevelStatus.Lock
    end
end

--怪物图标
function UIActivityN21CCLevelData:GetMonsterIcon()
    return self._monsterIcon1
end

--获取怪物在关卡详情界面的图标
function UIActivityN21CCLevelData:GetMonsterBigIcon()
    return self._monsterIcon
end

--怪物名字
function UIActivityN21CCLevelData:GetMonsterName()
    return self._monsterName
end

--推荐觉醒等级
function UIActivityN21CCLevelData:GetRecommendAwaken()
    return self._recommendAwaken
end

--推荐等级
function UIActivityN21CCLevelData:GetRecommendLV()
    return self._recommendLV
end

--关卡Id
function UIActivityN21CCLevelData:GetMissionId()
    return self._missionId
end

--关卡索引
function UIActivityN21CCLevelData:GetIndex()
    return self._levelIndex
end

--难度Id
function UIActivityN21CCLevelData:GetHardId()
    return self._hardId
end

--战斗关卡Id
function UIActivityN21CCLevelData:GetFightId()
    return self._fightId
end

--关卡名称
function UIActivityN21CCLevelData:GetName()
    return self._name
end

--关卡描述
function UIActivityN21CCLevelData:GetDes()
    return self._des
end

--所有词条组
function UIActivityN21CCLevelData:GetAffixGroups()
    return self._affixGroups
end

--获取普通的词条组
function UIActivityN21CCLevelData:GetCommonAffixGroups()
    local groups = {}
    for i = 1, #self._affixGroups do
        ---@type UIActivityN21CCAffixGroupsData
        local group = self._affixGroups[i]
        if group:GetUnLockScore() <= 0 then
            groups[#groups + 1] = group
        end
    end
    return groups
end

--获取积分解锁的词条组
function UIActivityN21CCLevelData:GetScoreUnLockAffixGroups()
    local groups = {}
    local tmp = {}
    for i = 1, #self._affixGroups do
        ---@type UIActivityN21CCAffixGroupsData
        local group = self._affixGroups[i]
        local unlockScore = group:GetUnLockScore()
        if unlockScore > 0 then
            local t = tmp[unlockScore]
            if t == nil then
                t = {}
                tmp[unlockScore] = t
            end
            t[#t + 1] = group
        end
    end
    for k, v in pairs(tmp) do
        groups[#groups + 1] = v
    end
    table.sort(groups, function(a, b)
        return a[1]:GetUnLockScore() < b[1]:GetUnLockScore()       
    end)
    return groups
end

--解锁关卡积分
function UIActivityN21CCLevelData:GetUnLockScore()
    return self._unlockScore
end

--解锁关卡基础积分
function UIActivityN21CCLevelData:GetBaseScore()
    return self._baseScore
end

--关卡状态
function UIActivityN21CCLevelData:GetStatus()
    return self._status
end

--关卡是否解锁
function UIActivityN21CCLevelData:IsLevelOpen()
    return self._status == UIActivityN21CCLevelStatus.Open
end

--最大积分
function UIActivityN21CCLevelData:GetMaxScore()
    return self._maxScore
end

--关卡解锁时间
function UIActivityN21CCLevelData:GetUnlockTime()
    local unlockTime = 0
    if self._missionComponentInfo.m_challenge_unlock_time and self._missionComponentInfo.m_challenge_unlock_time[self._missionId] then
        unlockTime = self._missionComponentInfo.m_challenge_unlock_time[self._missionId]
    end
    return unlockTime
end

--属性1
function UIActivityN21CCLevelData:GetElementIcon1()
    return self._elementIcon1
end

--属性2
function UIActivityN21CCLevelData:GetElementIcon2()
    return self._elementIcon2
end
