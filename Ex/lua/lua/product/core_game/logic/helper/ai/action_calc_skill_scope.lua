--[[-------------------------------------
    ActionCalcSkillScope 计算选择技能的范围
--]] -------------------------------------
require "ai_node_new"
---@class ActionCalcSkillScope : AINewNode
_class("ActionCalcSkillScope", AINewNode)
ActionCalcSkillScope = ActionCalcSkillScope

function ActionCalcSkillScope:Constructor()
end

function ActionCalcSkillScope:OnUpdate()
    ---@type AIComponentNew
    local aiCmpt = self.m_entityOwn:AI()
    local addRoundCount = self:GetLogicData(-1)
    local skillIndexX, skillIndexY = self:GetLogicData(-2), self:GetLogicData(-3)
    local nSkillID = self:GetConfigSkillID(skillIndexX, skillIndexY)
    aiCmpt:SetCurSkillScopeResult(addRoundCount, nSkillID)
    return AINewNodeStatus.Success
end