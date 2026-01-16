--[[-------------------------------------
    ActionCastSelectedSkill 释放选择的技能
--]] -------------------------------------
require "action_cast_skill_base"
---@class ActionCastSelectedSkill : ActionCastSkillBase
_class("ActionCastSelectedSkill", ActionCastSkillBase)
ActionCastSelectedSkill = ActionCastSelectedSkill
----------------------------------------------------------------
function ActionCastSelectedSkill:Constructor()
end

function ActionCastSelectedSkill:GetWorkSkillID()
    local nSkillID = self:GetLogicData(1)
    return nSkillID
end
----------------------------------------------------------------