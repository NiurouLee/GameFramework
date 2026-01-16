--[[------------------------------------------------------------------------------------------
    SkillDamageOnTargetDistanceEffectParam : 技能伤害效果参数
]] --------------------------------------------------------------------------------------------

require("skill_effect_param_base")

_class("SkillDamageOnTargetDistanceEffectParam", SkillEffectParamBase)
---@class SkillDamageOnTargetDistanceEffectParam: SkillEffectParamBase
SkillDamageOnTargetDistanceEffectParam = SkillDamageOnTargetDistanceEffectParam

function SkillDamageOnTargetDistanceEffectParam:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式

    self._targetCount = t.targetCount or 1 --目标数量
    self._baseValue = t.baseValue or 0 --基础伤害提升系数
    self._changeValue = t.changeValue or 0 --每一圈提升的系数
    self._skillIncreaseType = t.skillIncreaseType or ModifySkillIncreaseParamType.ActiveSkill
end

function SkillDamageOnTargetDistanceEffectParam:GetTargetCount()
    return self._targetCount
end

function SkillDamageOnTargetDistanceEffectParam:GetBaseValue()
    return self._baseValue
end

function SkillDamageOnTargetDistanceEffectParam:GetChangeValue()
    return self._changeValue
end

function SkillDamageOnTargetDistanceEffectParam:GetSkillIncreaseType()
    return self._skillIncreaseType
end

function SkillDamageOnTargetDistanceEffectParam:GetEffectType()
    return SkillEffectType.DamageOnTargetDistance
end

---获取百分比列表
function SkillDamageOnTargetDistanceEffectParam:GetDamagePercent()
    return self._percent
end

---获取伤害计算公式ID
function SkillDamageOnTargetDistanceEffectParam:GetDamageFormulaID()
    return self._formulaID
end
