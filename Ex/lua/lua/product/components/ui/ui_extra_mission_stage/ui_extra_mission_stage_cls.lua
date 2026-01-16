--region UIExtraMissionStage 番外关卡类
---@class UIExtraMissionStage:Object
_class("UIExtraMissionStage", Object)
UIExtraMissionStage = UIExtraMissionStage

function UIExtraMissionStage:Constructor()
    --[[
        --番外关卡类

        --关卡ID--
        --关卡名称--
        --关卡描述
        --时代信息
        --三星奖励物品列表
        --三星奖励物品数量列表
        --奖励物品列表
        --奖励物品数量列表
        --所需体力数--
        --怪物列表
        --三星条件1类型
        --三星条件1参数
        --三星条件2类型
        --三星条件2参数
        --三星条件3类型
        --三星条件3参数
        ]]
    self.id = 0 --关卡id
    self.name = "" --关卡名--前缀加 1-2
    self.desc = "" --介绍
    self.chapterIdxName = "" --章节索引名——第N章
    self.chapterIdxNameEn = "" --章节索引名——第N章
    self.chapterName = "" --章节名(mainstory)
    self.chapterNameEn = "" --章节名En
    self.icon = ""
    self.need_power = 0 --需要挑战体力
    self.three_star_condition = {} --三星条件
    self.nodeId = 0 --该关卡对应的路点id
    self.awards = {} --奖励
    self.enemies = {} --怪物
    self.story = {} --关卡对应的剧情信息

    self._extraMissionModule = GameGlobal.GetModule(ExtMissionModule)
end

---@param id number 关卡id
---@param idxStr string 第N章
---@param nameStr string 大章名
---@param nodeId number 该章节的路点id
function UIExtraMissionStage:Init(id, idxStr, nameStr, storyList)
    self.id = id

    self._cfg = Cfg.cfg_extra_mission[id]
    if self._cfg then
        self.name = StringTable.Get(self._cfg.Name)
        self.icon = self._cfg.Icon
        self.desc = self._cfg.Desc
        self.need_power = self._cfg.NeedPower --需要体力
        if self._cfg.Action == 1 then
            self.action = StageActionType.Fight
        else
            self.action = StageActionType.Conversation
        end
        --整合三星和普通奖励
        local idStr = self._cfg.ThreeStarAwardItemList
        local starCount = table.count(string.split(idStr, "|"))
        self.awards = {
            idStr = self._cfg.ThreeStarAwardItemList .. "|" .. self._cfg.AwardItemList,
            countStr = self._cfg.ThreeStarAwardItemCountList .. "|" .. self._cfg.AwardItemCountList,
            starCount = starCount
        }
        --敌方情报
        self.enemies = self:GetMonstersByMonsterListStr(self._cfg.MonsterList)
        --三星条件
        local ids = {
            self._cfg.ThreeStarCondition1,
            self._cfg.ThreeStarCondition2,
            self._cfg.ThreeStarCondition3
        }
        for i, v in ipairs(ids) do
            local cond = ExtraMissionStageCondition:New()
            cond:Init(i, v)
            table.insert(self.three_star_condition, cond)
        end
    end
    --剧情触发
    for i = 1, table.count(storyList) do
        local story = ExtStory:New()
        story:Init(storyList[i].id, storyList[i].type)
        table.insert(self.story, story)
    end
    self.chapterIdxName = StringTable.Get(idxStr)
    self.chapterIdxNameEn = StringTable.Get(idxStr .. "_en")
    self.chapterName = StringTable.Get(nameStr)
end

--[[
    ---@param star number 关卡星级
    function UIExtraMissionStage:UpdateStar(star)
        self.star = star or 0
    end
    ]]
---@param state DiscoveryStageState 关卡状态
function UIExtraMissionStage:UpdateState(state)
    self.state = state
end
---@param conditions number[] 状态id列表
function UIExtraMissionStage:UpdateCondition(conditions)
    for i, v in ipairs(conditions) do
        self.three_star_condition[v]:FlushSatisfy(true)
    end
end

---@private
---@param monstersStr string 怪物id字串
---@return table
---根据怪物id字串获取怪物id列表
function UIExtraMissionStage:GetMonstersByMonsterListStr(monstersStr)
    local items = {}
    local ids = {}
    if string.find(monstersStr, "|") then
        ids = string.split(monstersStr, "|")
    else
        ids[1] = monstersStr
    end
    for i = 1, #ids do
        table.insert(items, tonumber(ids[i]))
    end
    return items
end

---@public
---@return string, string 获取主线支线文本
function UIExtraMissionStage:GetStageMainBranchStr()
    local chapterInfo = Cfg.cfg_mission_chapter {MissionID = self.id}[1]
    dump(chapterInfo)
    local cnStr = ""
    local enStr = ""
    if chapterInfo then
        Log.fatal("### GetStageMainBranchStr " .. chapterInfo.ChapterType .. " ; " .. chapterInfo.ChapterType == 1)
        if chapterInfo.ChapterType == 1 then
            cnStr = StringTable.Get("str_discovery_main_chapter")
            enStr = StringTable.Get("str_discovery_main_chapter_en")
        else
            cnStr = StringTable.Get("str_discovery_branch_chapter")
            enStr = StringTable.Get("str_discovery_branch_chapter_en")
        end
    end
    return cnStr, enStr
end
--endregion

--region 三星条件类
---@class ExtraMissionStageCondition:Object
_class("ExtraMissionStageCondition", Object)
ExtraMissionStageCondition = ExtraMissionStageCondition

function ExtraMissionStageCondition:Constructor()
    self.id = 0 --条件id
    self.content = "" --描述
    self.satisfy = false --是否满足
    --
    self._extraMissionModule = GameGlobal.GetModule(ExtMissionModule)
end

---@param idx number 三星条件索引
---@param id number 三星条件id
function ExtraMissionStageCondition:Init(idx, id, desc, isSatisfy)
    self.id = id
    self.content = idx .. "." .. desc
    self:FlushSatisfy(isSatisfy)
end

---@param isSatisfy boolean
function ExtraMissionStageCondition:FlushSatisfy(isSatisfy)
    self.satisfy = isSatisfy or false
end
--endregion

--region 剧情类----------------------------------------------------
---@class ExtStory:Object
_class("ExtStory", Object)
ExtStory = ExtStory

function ExtStory:Constructor()
    self.id = 0
    self.stageId = 0
    self.activeType = nil
    self._cfg = Cfg.cfg_extra_mission_story
end
---@public
---@param stageId number 关卡id
function ExtStory:Init(storyID, storyType)
    self.id = storyID
    if storyType == 1 then
        self.activeType = StoryTriggerType.BeforeFight
    elseif storyType == 2 then
        self.activeType = StoryTriggerType.AfterFight
    else
        self.activeType = StoryTriggerType.Node
    end
end
--endregion
