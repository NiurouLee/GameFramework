--------------------------难度类型
---@class UILostLandEnterType
local UILostLandEnterType = {
    EASY = 1,
    DIFF = 2,
    HELL = 3
}
_enum("UILostLandEnterType", UILostLandEnterType)
----------------------------难度解锁状态
---@class UILostLandEnterLockType
local UILostLandEnterLockType = {
    UNLOCK = 1,
    LOCK = 2,
    CANUNLOCK = 3,
    CHOOSE = 4
}
_enum("UILostLandEnterLockType", UILostLandEnterLockType)

--------------------------关卡类型
---@class UILostLandMissionType
local UILostLandMissionType = {
    NORMAL = 1,
    BOSS = 2,
    PLOT = 3
}
_enum("UILostLandMissionType", UILostLandMissionType)
--------------------------关卡解锁状态
---@class UILostLandMissionLockType
local UILostLandMissionLockType = {
    PASS = 1,
    UNLOCK = 2,
    LOCK = 3
}
_enum("UILostLandMissionLockType", UILostLandMissionLockType)

--------------------------筛选类型
---@class UILostLandFilterType
local UILostLandFilterType = {
    AND = 1,
    OR = 2
}
_enum("UILostLandFilterType", UILostLandFilterType)
--------------------------领奖状态，推荐奖励
---@class UILostLandRecommendAwardStatus
local UILostLandRecommendAwardStatus = {
    Got = 1,
    Not = 2
}
_enum("UILostLandRecommendAwardStatus", UILostLandRecommendAwardStatus)

----------------------------难度数据
_class("UILostLandEnterData", Object)
---@class UILostLandEnterData:Object
UILostLandEnterData = UILostLandEnterData

function UILostLandEnterData:Constructor(enterid, lockType, svrCfg, levelGroupCfg)
    local cfg = Cfg.cfg_lost_land_enter[enterid]
    if not cfg then
        Log.error("###[UILostLandEnterData] cfg_lost_land_enter is nil ! id --> ", enterid)
    end
    self._type = svrCfg.difficulty

    ---@type UILostLandEnterLockType
    self._lockType = lockType

    self._enterID = enterid

    self._cg = cfg.BG

    self._name = cfg.EnterName

    self._recommendGrade = cfg.RecommendGrade
    self._recommendLv = cfg.RecommendLv

    local width = {[1] = 0, [2] = 0}
    if cfg.ShowItemWidth then
        width = {[1] = cfg.ShowItemWidth[1], [2] = cfg.ShowItemWidth[2]}
    end
    self._width = width

    self._condition = svrCfg.unlock_condition

    self._missionTable = self:CreateMissionTable(levelGroupCfg)

    self._viewAward = self:CreateViewAward(levelGroupCfg)
end

--奖励预览，需要获取改难度的所有关卡，然后取奖励合并,排序
function UILostLandEnterData:CreateViewAward(levelGroupCfg)
    local awardMap = {}
    for key, value in pairs(levelGroupCfg) do
        local diff = value.difficulty
        if diff == self._type then
            ---@type RoleAsset[]
            local awards = value.award
            for i = 1, #awards do
                local award = awards[i]
                if not awardMap[award.assetid] then
                    awardMap[award.assetid] = award.count
                else
                    awardMap[award.assetid] = awardMap[award.assetid] + award.count
                end
            end
        end
    end
    ---@type ItemAsset[]
    local _awardList = {}
    for key, value in pairs(awardMap) do
        local itemAsset = ItemAsset:New()
        itemAsset.assetid = key
        itemAsset.count = value
        table.insert(_awardList, itemAsset)
    end
    --sort
    table.sort(
        _awardList,
        function(a, b)
            local cfg_a = Cfg.cfg_item[a.assetid]
            local cfg_b = Cfg.cfg_item[b.assetid]
            if cfg_a.Color == cfg_b.Color then
                if cfg_a.BagSortIndex == cfg_b.BagSortIndex then
                    return a.assetid < b.assetid
                else
                    return cfg_a.BagSortIndex > cfg_b.BagSortIndex
                end
            else
                return cfg_a.Color > cfg_b.Color
            end
        end
    )
    return _awardList
end

--创建难度的关卡数据
function UILostLandEnterData:CreateMissionTable(levelGroupCfg)
    local missionTable = {}
    for key, value in pairs(levelGroupCfg) do
        local diff = value.difficulty
        if diff == self._type then
            if not missionTable[value.group_seq_id] then
                missionTable[value.group_seq_id] = {}
            end
            missionTable[value.group_seq_id][value.seq_in_group] = key
        end
    end
    return missionTable
end
function UILostLandEnterData:GetEnterID()
    return self._enterID
end

--难度
function UILostLandEnterData:GetType()
    return self._type
end
--解锁状态
function UILostLandEnterData:GetLockState()
    return self._lockType
end
function UILostLandEnterData:UnLock()
    self._lockType = UILostLandEnterLockType.UNLOCK
end
--背景图
function UILostLandEnterData:GetCg()
    return self._cg
end
--名字
function UILostLandEnterData:GetName()
    return self._name
end
--奖励预览
function UILostLandEnterData:GetViewAward()
    return self._viewAward
end
--推荐等级
function UILostLandEnterData:GetRecommendLv()
    return self._recommendLv
end
--推荐觉醒等级
function UILostLandEnterData:GetRecommendGrade()
    return self._recommendGrade
end
--条件
function UILostLandEnterData:GetCondition()
    return self._condition
end
--关卡组
function UILostLandEnterData:GetMissionTable()
    return self._missionTable
end
--关卡组内的item的宽度
function UILostLandEnterData:GetItemShowWidth()
    return self._width
end

-----------------------关卡数据
_class("UILostLandMissionData", Object)
---@class UILostLandMissionData:Object
UILostLandMissionData = UILostLandMissionData

---@param missionInfo MissionInfo
function UILostLandMissionData:Constructor(missionid, svrCfg, missionInfo, currentid)
    self._id = missionid
    local cfg = Cfg.cfg_lost_land_mission[missionid]
    if not cfg then
        Log.error("###[UILostLandMissionData] cfg_lost_land_mission is nil ! id --> ", missionid)
    end

    ---@type UILostLandMissionType
    self._type = nil
    if svrCfg.level_type == 1 then
        self._type = UILostLandMissionType.NORMAL
    elseif svrCfg.level_type == 2 then
        self._type = UILostLandMissionType.BOSS
    end

    self._passTimes = missionInfo.pass_time
    if currentid ~= nil then
        if currentid == missionid then
            self._lock = UILostLandMissionLockType.UNLOCK
        else
            if self._passTimes <= 0 then
                self._lock = UILostLandMissionLockType.LOCK
            else
                self._lock = UILostLandMissionLockType.PASS
            end
        end
    else
        self._lock = UILostLandMissionLockType.PASS
    end

    self._word = missionInfo.wordd_id

    self._award = svrCfg.award

    self._missionName = cfg.MissionName

    self._petAward = missionInfo.recommend_reward_num

    self._recommendGrade = cfg.RecommendGrade
    self._recommendLv = cfg.RecommendLv

    self._levelid = missionInfo.level_id
end
--解锁状态
function UILostLandMissionData:GetLockType()
    return self._lock
end
--通关情况
function UILostLandMissionData:GetPassTimes()
    return self._passTimes
end

--战斗id
function UILostLandMissionData:GetLevelID()
    return self._levelid
end
--关卡类型
function UILostLandMissionData:GetType()
    return self._type
end
--关卡id
function UILostLandMissionData:GetID()
    return self._id
end
--词条
function UILostLandMissionData:GetWord()
    return self._word
end
--奖励
function UILostLandMissionData:GetAward()
    return self._award
end
--推荐奖励进度
function UILostLandMissionData:GetPetAward()
    return self._petAward
end
--关卡名字
function UILostLandMissionData:GetMissionName()
    return self._missionName
end
--推荐等级
function UILostLandMissionData:GetRecommendLv()
    return self._recommendLv
end
--推荐觉醒等级
function UILostLandMissionData:GetRecommendGrade()
    return self._recommendGrade
end
