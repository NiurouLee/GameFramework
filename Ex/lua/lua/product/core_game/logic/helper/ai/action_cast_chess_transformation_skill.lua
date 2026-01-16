--[[-------------------------------------
    ActionCastChessTransformationSkill 释放国际象棋兵的变身技能
--]] -------------------------------------
require "ai_node_new"
---@class ActionCastChessTransformationSkill : ActionCastSkillBase
_class("ActionCastChessTransformationSkill", ActionCastSkillBase)
ActionCastChessTransformationSkill = ActionCastChessTransformationSkill
----------------------------------------------------------------
function ActionCastChessTransformationSkill:Constructor()
end

function ActionCastChessTransformationSkill:GetWorkSkillID()
    local skillIndexX = self:GetLogicData(-1)

    ---@type BattleFlagsComponent
    local battleFlags = self._world:BattleFlags()

    local skillIndexY = battleFlags:GetChessTransformationIndex()
    local vecSkillList = self:GetConfigSkillList()

    local skillCount = table.count(vecSkillList[skillIndexX])

    skillIndexY = skillIndexY % skillCount
    if skillIndexY == 0 then
        skillIndexY = skillCount
    end

    local nSkillID = self:GetConfigSkillID(skillIndexX, skillIndexY)

    -- --根据自己属性变身
    -- ---@type AttributesComponent
    -- local attributeCmpt = self.m_entityOwn:Attributes()
    -- local curElement = attributeCmpt:GetAttribute("Element")
    -- local supplement = (curElement - 1) * 10
    -- nSkillID = nSkillID + supplement

    return nSkillID
end
----------------------------------------------------------------
