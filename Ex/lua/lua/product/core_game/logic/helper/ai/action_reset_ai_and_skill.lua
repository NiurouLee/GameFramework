--[[-------------------------------------
    ActionResetAIAndSkill 将技能轮播重置成开始，并且重置技能，用在变身之后
--]] -------------------------------------
require "ai_node_new"

---@class ActionResetAIAndSkill : AINewNode
_class("ActionResetAIAndSkill", AINewNode)
ActionResetAIAndSkill = ActionResetAIAndSkill

function ActionResetAIAndSkill:Constructor()
end

function ActionResetAIAndSkill:OnBegin()
    self:SetRuntimeData("RoundCount", 0)
    self:SetRuntimeData("NextRoundCount", 1)

    --已经变身，取出变身后的id
    local MonsterID = self.m_entityOwn:MonsterID():GetMonsterID()
    ---@type ConfigService
    local cfgService = self._world:GetService("Config")
    ---@type MonsterConfigData
    local monsterConfigData = cfgService:GetMonsterConfigData()
    local crazySkillList = monsterConfigData:GetMonsterSkillIDs(MonsterID)
    self:SetSkillList(crazySkillList)
    self.m_logicOwn:ReSelectWorkSkill()
    self:PrintLog("重置回合数和技能列表")

    local aiList = monsterConfigData:GetMonsterAIID(MonsterID)
    if aiList[1] then
        self.m_entityOwn:ReplaceAI(AILogicPeriodType.Main, {aiList[1][1]}, aiList[1][2])
    end
end

function ActionResetAIAndSkill:OnUpdate(dt)
    return AINewNodeStatus.Success
end
