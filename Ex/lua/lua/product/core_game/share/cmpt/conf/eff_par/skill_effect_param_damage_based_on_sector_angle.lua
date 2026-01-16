require("skill_effect_param_base")

---@class SkillEffectParam_DamageBasedOnSectorAngle : SkillEffectParamBase
_class("SkillEffectParam_DamageBasedOnSectorAngle", SkillEffectParamBase)
SkillEffectParam_DamageBasedOnSectorAngle = SkillEffectParam_DamageBasedOnSectorAngle

function SkillEffectParam_DamageBasedOnSectorAngle:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式
    self._maxAngle = t.maxAngle
    self._minDamageRate = t.minDamageRate

    self._skillIncreaseType = t.skillIncreaseType or ModifySkillIncreaseParamType.ActiveSkill
    self._angleDamageRate = 1
end

function SkillEffectParam_DamageBasedOnSectorAngle:GetEffectType()
    return SkillEffectType.DamageBasedOnSectorAngle
end

function SkillEffectParam_DamageBasedOnSectorAngle:GetMaxAngle()
    return self._maxAngle
end
function SkillEffectParam_DamageBasedOnSectorAngle:GetMinDamageRate()
    return self._minDamageRate
end
---获取百分比列表
function SkillEffectParam_DamageBasedOnSectorAngle:GetDamagePercent()
    return self._percent
end

---获取伤害计算公式ID
function SkillEffectParam_DamageBasedOnSectorAngle:GetDamageFormulaID()
    return self._formulaID
end
function SkillEffectParam_DamageBasedOnSectorAngle:GetSkillIncreaseType()
    return self._skillIncreaseType
end

--传入的最终伤害比例
function SkillEffectParam_DamageBasedOnSectorAngle:SetAngleDamageRate(rate)
    self._angleDamageRate = rate
end
function SkillEffectParam_DamageBasedOnSectorAngle:GetAngleDamageRate()
    return self._angleDamageRate
end
