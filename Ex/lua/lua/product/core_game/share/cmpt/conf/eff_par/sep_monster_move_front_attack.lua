require("skill_damage_effect_param")

_class("SkillEffectParamMonsterMoveFrontAttack", SkillEffectParamBase)
---@class SkillEffectParamMonsterMoveFrontAttack: SkillEffectParamBase
SkillEffectParamMonsterMoveFrontAttack = SkillEffectParamMonsterMoveFrontAttack

function SkillEffectParamMonsterMoveFrontAttack:Constructor(t)
    self._skillID = t.skillID
    self._moveStep = t.moveStep
end

function SkillEffectParamMonsterMoveFrontAttack:GetEffectType()
    return SkillEffectType.MonsterMoveFrontAttack
end
function SkillEffectParamMonsterMoveFrontAttack:GetCheckSkillID()
    return self._skillID
end
function SkillEffectParamMonsterMoveFrontAttack:GetMoveStep()
    return self._moveStep
end