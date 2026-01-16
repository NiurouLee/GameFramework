--[[-------------------------------------
    ActionResetRoundCount 将技能轮播重置成开始
--]] -------------------------------------
require "ai_node_new"

---@class ActionResetRoundCount : AINewNode
_class("ActionResetRoundCount", AINewNode)
ActionResetRoundCount = ActionResetRoundCount

function ActionResetRoundCount:Constructor()
end

function ActionResetRoundCount:OnBegin()
    local nLoopLimit = self:GetLogicData(-1)
    if nil == nLoopLimit or nLoopLimit <= 0 then
        nLoopLimit = self:GetRuntimeData("SkillCount") or 1
    end
    self:SetRuntimeData("RoundCount", nLoopLimit)
    self:SetRuntimeData("NextRoundCount", 1)
    self.m_logicOwn:ReSelectWorkSkill()
    self:PrintLog( "重置回合数" )
end

function ActionResetRoundCount:OnUpdate(dt)
    return AINewNodeStatus.Success
end
