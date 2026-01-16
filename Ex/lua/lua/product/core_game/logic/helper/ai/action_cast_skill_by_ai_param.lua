--[[-------------------------------------
    ActionCastSkillByAIParam 释放cfg_ai中AIParam中配的技能
--]] -------------------------------------
require "ai_node_new"
---@class ActionCastSkillByAIParam : ActionCastSkillBase
_class("ActionCastSkillByAIParam", ActionCastSkillBase)
ActionCastSkillByAIParam = ActionCastSkillByAIParam

function ActionCastSkillByAIParam:GetWorkSkillID()
    local skills = self:GetConfigSkillList()
    local idx = self:GetLogicData(-1) or 1
    local skillId = skills[idx]
    return skillId
end
