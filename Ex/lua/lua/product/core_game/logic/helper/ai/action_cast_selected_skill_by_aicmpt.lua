--[[-------------------------------------
    ActionCastSelectedSkillByAiCmpt 释放选择的技能
--]] -------------------------------------
require "action_cast_skill_base"
---@class ActionCastSelectedSkillByAiCmpt : ActionCastSkillBase
_class("ActionCastSelectedSkillByAiCmpt", ActionCastSkillBase)
ActionCastSelectedSkillByAiCmpt = ActionCastSelectedSkillByAiCmpt
----------------------------------------------------------------
function ActionCastSelectedSkillByAiCmpt:Constructor()
end

function ActionCastSelectedSkillByAiCmpt:GetWorkSkillID()
    ---@type Entity
    local entityCaster = self.m_entityOwn
    local aiComponent = entityCaster:AI()
    local nSelectedSkillID = aiComponent:GetSelectSkillID()
    if nSelectedSkillID == 0 then
        return self:GetLogicData(1)
    end
    return nSelectedSkillID
end
----------------------------------------------------------------