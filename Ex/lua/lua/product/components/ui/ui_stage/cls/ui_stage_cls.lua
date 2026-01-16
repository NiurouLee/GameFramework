--region DiscoveryStage 关卡类
---@class DiscoveryStage:Object
---@field id number 关卡id
---@field type DiscoveryStageType 普通战斗关，Boss战斗关，剧情关
---@field sectionId number 部id
_class("DiscoveryStage", Object)
DiscoveryStage = DiscoveryStage

function DiscoveryStage:Constructor()
    self.id = 0
    self.type = DiscoveryStageType.FightNormal
    self.stageIdx = "" --1-1
    self.name = "" --关卡名
    self.icon = ""
    self.desc = ""
    self.longDesc = "" --长描述
    self.cg = "" --背景
    self.need_power = 0
    self.awards = {}
    ---@type Enemy[]
    self.enemies = {}
    ---@type DiscoveryStoryList
    self.story = nil --关卡对应的剧情信息
    ---@type DiscoveryStageState
    self.state = nil
    self.star = 0
    ---@type StageCondition[]
    self.three_star_condition = {} --三星条件
    self.nodeId = 0 --该关卡对应的路点id
    ---@type number[]
    self.prevStageId = {} --该关卡的前置关卡id
    self.unlockTimestamp = 0 --关卡解锁时间戳
    ---@type MissionModule
    self._module = GameGlobal.GetModule(MissionModule)
    ---@type DiscoveryData
    self._data = self._module:GetDiscoveryData()
    self.sectionId = 0
end

---@param id number 关卡id
---@param nodeId number 该章节的路点id
function DiscoveryStage:Init(id, nodeId)
    self.id = id
    self.nodeId = nodeId
    local cfg = Cfg.cfg_mission[id]
    if cfg then
        if cfg.Type == 1 then
            self.type = DiscoveryStageType.FightNormal
        elseif cfg.Type == 2 then
            self.type = DiscoveryStageType.FightBoss
        else
            self.type = DiscoveryStageType.Plot
        end
        self.stageIdx = DiscoveryStage.GetStageIndexString(id)
        self.name = StringTable.Get(cfg.Name)
        self.icon = cfg.Icon
        self.desc = StringTable.Get(cfg.Desc)
        self.longDesc = StringTable.Get(cfg.Desc .. "_long")
        self.need_power = cfg.NeedPower
        self.prevStageId = cfg.NeedMissionList
        self.unlockTimestamp = cfg.UnlockTime or 0
        self:FormatAwards(cfg)
        --敌方情报
        self.enemies = cfg.MonsterList
        --三星条件
        local ids = {
            cfg.ThreeStarCondition1,
            cfg.ThreeStarCondition2,
            cfg.ThreeStarCondition3
        }
        for i, v in ipairs(ids) do
            local cond = StageCondition:New()
            cond:Init(i, v)
            table.insert(self.three_star_condition, cond)
        end
        self.sectionId = cfg.Section
    end
    local cfg_mission_chapter = Cfg.cfg_mission_chapter {MissionID = self.id}[1]
    if cfg_mission_chapter then
        self.cg = cfg_mission_chapter.BG
    end
    --剧情触发
    self.story = DiscoveryStoryList:New()
    self.story:Init(self.id)
end

function DiscoveryStage.GetStageIndexString(stageid)
    if stageid == nil then
        return ""
    end
    --MSG40811	【需测试】简章标题配置支持字母配置		小开发任务-待开发	靳策, 1951	05/05/2022
    --根据策划需求，关卡名读waypoint配置
    local cfgs = Cfg.cfg_mission_chapter {MissionID = stageid}
    if cfgs and #cfgs == 1 then
        local id = cfgs[1].WayPointID
        local waypointCfg = Cfg.cfg_waypoint[id]
        if not waypointCfg then
            Log.fatal("Key not found in cfg_waypoint:", id)
            return
        end
        return StringTable.Get(waypointCfg.Name)
    else
        Log.fatal("cfg_mission_chapter error, MissionID:", stageid)
    end

    --[[ 旧的逻辑
    local cfg_mission = Cfg.cfg_mission[stageid]
    local stageStr = ""
    if cfg_mission then
        local arrMissionIdx = cfg_mission.Chapter
        if arrMissionIdx then
            local len = table.count(arrMissionIdx)
            --小任务，只显示两个，支线也是
            local showCount = len
            local maxCount = 2
            if showCount > maxCount then
                showCount = maxCount
            end
            for i = 1, showCount do
                local num = arrMissionIdx[i]
                stageStr = stageStr .. num
                if i < showCount then
                    stageStr = stageStr .. UIConst.ConnectorString
                end
            end
            if len == 3 then --分支
                stageStr = UIConst.BranchMissionIndexPrefix .. stageStr
            end
        end
    end
    return stageStr
]]
end

---@param cfg table
function DiscoveryStage:FormatAwards(cfg)
    self.awards = {}
    if not self:HasPassThreeStar() then
        local awardsStar = self:GetSortedArr(AwardType.ThreeStar, cfg, StageAwardType.Star)
        if awardsStar then
            for i, v in ipairs(awardsStar) do
                self.awards[#self.awards + 1] = v
            end
        end
    end
    if not self:HasFirstPass() then
        local awardsFirst = self:GetSortedArr(AwardType.First, cfg, StageAwardType.First)
        if awardsFirst then
            for i, v in ipairs(awardsFirst) do
                self.awards[#self.awards + 1] = v
            end
        end
    end
    local normalArr = self:GetSortedArr(AwardType.Pass, cfg, StageAwardType.Normal)
    if normalArr then
        for i, v in ipairs(normalArr) do
            self.awards[#self.awards + 1] = v
        end
    end
end

---@param list Table ItemID=XXX, Count=XXX
---@param stageAwardType StageAwardType
function DiscoveryStage:GetSortedArr(awardType, cfg, stageAwardType)
    local list = UICommonHelper:GetInstance():GetDropByAwardType(awardType, cfg)
    local vecSort = SortedArray:New(Algorithm.COMPARE_CUSTOM, DiscoveryStage._LessComparer)
    if list then
        for i, v in ipairs(list) do
            local award = Award:New()
            award:InitWithCount(v.ItemID, v.Count, v.Type)
            award:FlushType(stageAwardType)
            vecSort:Insert(award)
        end
    end
    return vecSort.elements
end

-- 是否通过三星
function DiscoveryStage:HasPassThreeStar()
    for index, value in ipairs(self.three_star_condition) do
        if not value.satisfy then
            return false
        end
    end
    return true
end

-- 是否首通
function DiscoveryStage:HasFirstPass()
    return self.state == DiscoveryStageState.Nomal
end

---奖励物品排序规则：品质降序，id升序
---@param nItemIDA Award
---@param nItemIDB Award
DiscoveryStage._LessComparer = function(nItemIDA, nItemIDB)
    return -1
end

---@param star number 关卡星级
function DiscoveryStage:UpdateStar(star)
    self.star = star or 0
end
---@param state DiscoveryStageState 关卡状态
function DiscoveryStage:UpdateState(state)
    self.state = state
    local cfg = Cfg.cfg_mission[self.id]
    self:FormatAwards(cfg)
end
---@param conditions number[] 状态id列表
function DiscoveryStage:UpdateCondition(conditions)
    local l_cur_star_num = 0
    for index, value in ipairs(self.three_star_condition) do
        if value.satisfy == true then
            l_cur_star_num = l_cur_star_num + 1
        end
    end
    local l_finish_star_num = #conditions

    for index, value in ipairs(self.three_star_condition) do
        if l_finish_star_num == l_cur_star_num then
            value:FlushSatisfy(false)
        end
        for i, v in ipairs(conditions) do
            if v == index then
                value:FlushSatisfy(true)
            end
        end
    end

    local cfg = Cfg.cfg_mission[self.id]
    self:FormatAwards(cfg)
end

---该关卡是否有剧情
function DiscoveryStage:IsThereStory()
    if self.story then
        return self.story:Count() > 0
    end
    return false
end

---获取该关卡对应的章节，如果找不到则返回最后一章
function DiscoveryStage:GetChapter()
    local chapter = self._data:GetChapterByStageId(self.id)
    if chapter then
        return chapter
    end
    return self._data:GetLastChapter()
end

---可打等级
function DiscoveryStage:NeedLevel()
    local cfg = Cfg.cfg_mission[self.id]
    if cfg then
        return cfg.NeedLevel
    end
    return 0
end
---玩家等级是否达到打该关卡所需等级
function DiscoveryStage:LevelReach()
    ---@type RoleModule
    local roleModule = GameGlobal.GetModule(RoleModule)
    local lv = roleModule:GetLevel()
    if lv >= self:NeedLevel() then
        return true
    end
end

---是否为引导关（强制关）
function DiscoveryStage:IsGuideStage()
    return DiscoveryStage.IsGuideStageId(self.id)
end
---是否为引导关（强制关）
function DiscoveryStage.IsGuideStageId(id)
    if Cfg.cfg_mission_guide()[id] then
        return true
    end
    return false
end
--endregion

--region StageCondition
---@class StageCondition:Object
_class("StageCondition", Object)
StageCondition = StageCondition

function StageCondition:Constructor()
    self.id = 0 --条件id
    self.content = "" --描述
    self.satisfy = false --是否满足
    --
    self._module = GameGlobal.GetModule(MissionModule)
end
---@param idx number 三星条件索引
---@param id number 三星条件id
function StageCondition:Init(idx, id)
    self.id = id or 0
    local desc = self._module:Get3StarConditionDesc(id, "FFA222") or ""
    self.content = desc
end
---@param isSatisfy boolean
function StageCondition:FlushSatisfy(isSatisfy)
    self.satisfy = isSatisfy or false
end
--endregion

--region DiscoveryStoryList
---@class DiscoveryStoryList:Object
_class("DiscoveryStoryList", Object)
DiscoveryStoryList = DiscoveryStoryList

function DiscoveryStoryList:Constructor()
    self.stageId = 0
    ---@type DiscoveryStory[]
    self.list = {}
    self._cfg = Cfg.cfg_mission_story
end
---@public
---@param stageId number 关卡id
function DiscoveryStoryList:Init(stageId)
    local cfgv = self._cfg[stageId]
    self.stageId = stageId
    if cfgv and cfgv.StoryID then
        for i, v in ipairs(cfgv.StoryID) do
            local story = DiscoveryStory:New()
            story:Init(v, cfgv.StoryActiveType[i])
            table.insert(self.list, story)
        end
    end
end

---@param storyType StoryTriggerType 剧情触发类型
---根据剧情触发类型获取剧情信息
function DiscoveryStoryList:GetStoryByStoryType(storyType)
    if not self.list then
        return
    end
    for i, v in ipairs(self.list) do
        if v.activeType == storyType then
            return v
        end
    end
end

---获取剧情数
function DiscoveryStoryList:Count()
    if not self.list then
        return 0
    end
    return table.count(self.list)
end
--endregion

--region DiscoveryStory
---@class DiscoveryStory:Object
_class("DiscoveryStory", Object)
DiscoveryStory = DiscoveryStory

function DiscoveryStory:Constructor()
    self.id = 0
    ---@type StoryTriggerType
    self.activeType = nil
end
---@public
function DiscoveryStory:Init(storyId, storyType)
    self.id = storyId
    if storyType == 1 then
        self.activeType = StoryTriggerType.BeforeFight
    elseif storyType == 2 then
        self.activeType = StoryTriggerType.AfterFight
    elseif storyType == 3 then
        self.activeType = StoryTriggerType.Node
    elseif storyType == 4 then
        self.activeType = StoryTriggerType.BattleBefore
    elseif storyType == 5 then
        self.activeType = StoryTriggerType.BattleAfter
    end
end
--endregion

--- @class DiscoveryStageState
local DiscoveryStageState = {
    Nomal = 0, --已通关
    CanPlay = 1 --可挑战
}
_enum("DiscoveryStageState", DiscoveryStageState)

--- @class DiscoveryStageType
local DiscoveryStageType = {
    FightNormal = 1, --普通战斗关卡
    FightBoss = 2, --Boss战斗关卡
    Plot = 3, --剧情关卡
    Node = 4, --节点关卡
    SNode = 5 --节点关卡
}
_enum("DiscoveryStageType", DiscoveryStageType)

--- @class StoryTriggerType
local StoryTriggerType = {
    BeforeFight = 1, --战前触发
    AfterFight = 2, --战后触发
    Node = 3, --路点触发
    BattleBefore = 4, --局内战前
    BattleAfter = 5 --局内战后
}
_enum("StoryTriggerType", StoryTriggerType)

---@class UISerialAutoFightOptionCampParams:Object
_class("UISerialAutoFightOptionCampParams", Object)
UISerialAutoFightOptionCampParams = UISerialAutoFightOptionCampParams
function UISerialAutoFightOptionCampParams:Constructor(pointComp,campType,forceTitleState,needTicket,componentId,campaignMissionParams)
    self._pointComp = pointComp
    self._campType = campType
    self._forceTitleState = forceTitleState
    self._needTicket = needTicket
    self._componentId = componentId
    self._campaignMissionParams = campaignMissionParams
end