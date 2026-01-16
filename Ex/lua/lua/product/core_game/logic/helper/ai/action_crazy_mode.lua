--[[-------------------------------------
    ActionCrazyMode 耶斯特夏尔狂暴模式
--]] -------------------------------------
require "ai_node_new"
---@class ActionCrazyMode:AINewNode
_class("ActionCrazyMode", AINewNode)
ActionCrazyMode = ActionCrazyMode

function ActionCrazyMode:Constructor()
    ---@type MainWorld
    self._world = nil
    self._crazy = false
end

---@param cfg table
---@param context CustomNodeContext
function ActionCrazyMode:InitializeNode(cfg, context, parentNode, configData)
    ActionCrazyMode.super.InitializeNode(self, cfg, context, parentNode, configData)
end

function ActionCrazyMode:OnUpdate()
    if self._crazy then
        return AINewNodeStatus.Failure
    end

    local crazyMonsterID = self:GetLogicData(-1)
    local sisterMonsterID = self:GetLogicData(-2)

    --判断另一个boss是否死亡
    self._crazy = true
    local group = self._world:GetGroup(self._world.BW_WEMatchers.MonsterID)
    for _, e in ipairs(group:GetEntities()) do
        if e:HasDeadMark() == false and e:MonsterID():GetMonsterClassID() == sisterMonsterID then
            self._crazy = false
            break
        end
    end

    if self._crazy then
        ---@type ConfigService
        local cfgService = self._world:GetService("Config")
        ---@type MonsterConfigData
        local monsterConfigData = cfgService:GetMonsterConfigData()
        local raceType = monsterConfigData:GetMonsterRaceType(crazyMonsterID)
        local monsterType = monsterConfigData:GetMonsterType(crazyMonsterID)
        local monsterGroupID = monsterConfigData:GetMonsterGroupID(crazyMonsterID)
        local monsterClassID = monsterConfigData:GetMonsterClassID(crazyMonsterID)
        local monsterCampType = monsterConfigData:GetMonsterCampType(crazyMonsterID)
        self.m_entityOwn:ReplaceMonsterID(crazyMonsterID, raceType, monsterType, monsterGroupID, monsterClassID,monsterCampType) -- 更换ID

        ---@type MonsterConfigData
        local monsterConfig = cfgService:GetMonsterConfigData()
        local crazySkillList = monsterConfig:GetMonsterSkillIDs(crazyMonsterID)
        self:SetSkillList(crazySkillList)
        self:SetRuntimeData("RoundCount", 1)
        self:SetRuntimeData("NextRoundCount", 2)
        self.m_logicOwn:ReSelectWorkSkill()
        self.m_entityOwn:ReplaceCrazyMode()
        return AINewNodeStatus.Success
    end

    return AINewNodeStatus.Failure
end
