--[[-------------------------------------
    ActionCastSpecifiedSkill 释放选择的技能
--]] -------------------------------------
require "ai_node_new"
---@class ActionCastSpecifiedSkill : ActionCastSkillBase
_class("ActionCastSpecifiedSkill", ActionCastSkillBase)
ActionCastSpecifiedSkill = ActionCastSpecifiedSkill
----------------------------------------------------------------
function ActionCastSpecifiedSkill:Constructor()
end

function ActionCastSpecifiedSkill:GetWorkSkillID()
    local skillIndexX, skillIndexY = self:GetLogicData(-1), self:GetLogicData(-2)
    local nSkillID = self:GetConfigSkillID(skillIndexX, skillIndexY)
    return nSkillID
end
----------------------------------------------------------------
