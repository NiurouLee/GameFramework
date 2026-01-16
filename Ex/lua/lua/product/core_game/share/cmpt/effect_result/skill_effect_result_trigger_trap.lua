require("skill_effect_result_base")

_class("SkillEffectResultTriggerTrap", SkillEffectResultBase)
---@class SkillEffectResultTriggerTrap: SkillEffectResultBase
SkillEffectResultTriggerTrap = SkillEffectResultTriggerTrap

function SkillEffectResultTriggerTrap:Constructor(entityID, trapID)
    self._entityID = entityID
    self._trapID = trapID
end

function SkillEffectResultTriggerTrap:GetEffectType()
    return SkillEffectType.TriggerTrap
end

function SkillEffectResultTriggerTrap:GetEntityID()
    return self._entityID
end

function SkillEffectResultTriggerTrap:GetTrapID()
    return self._trapID
end
