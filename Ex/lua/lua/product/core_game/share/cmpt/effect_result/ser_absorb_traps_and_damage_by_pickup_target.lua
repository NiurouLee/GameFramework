require("skill_effect_result_base")

_class("SkillEffectAbsorbTrapsAndDamageByPickupTargetResult", SkillEffectResultBase)
---@class SkillEffectAbsorbTrapsAndDamageByPickupTargetResult: SkillEffectResultBase
SkillEffectAbsorbTrapsAndDamageByPickupTargetResult = SkillEffectAbsorbTrapsAndDamageByPickupTargetResult

function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:Constructor(trapEntityIDs, damageResultArray)
    self._trapEntityIDs = trapEntityIDs
    self._damageResultArray = damageResultArray
    self._finalAttackIndex = nil
end

function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:GetTrapEntityIDs()
    return self._trapEntityIDs
end

function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:GetDamageResultArray()
    return self._damageResultArray
end

function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:GetEffectType()
    return SkillEffectType.AbsorbTrapsAndDamageByPickupTarget
end

--获取最后一击
function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:GetFinalAttackIndex()
    return self._finalAttackIndex
end

--设置最后一击
function SkillEffectAbsorbTrapsAndDamageByPickupTargetResult:SetFinalAttackIndex(index)
    self._finalAttackIndex = index
end