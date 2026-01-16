--[[------------------------------------------------------------------------------------------
    MultipleScopesDealMultipleDamage = 99, --同一个目标在被技能范围覆盖多次，造成多次伤害
]] --------------------------------------------------------------------------------------------

require("skill_effect_param_base")

_class("SkillMultipleScopesDealMultipleDamageEffectParam", SkillEffectParamBase)
---@class SkillMultipleScopesDealMultipleDamageEffectParam: SkillEffectParamBase
SkillMultipleScopesDealMultipleDamageEffectParam = SkillMultipleScopesDealMultipleDamageEffectParam

function SkillMultipleScopesDealMultipleDamageEffectParam:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式
end

function SkillMultipleScopesDealMultipleDamageEffectParam:GetEffectType()
    return SkillEffectType.MultipleScopesDealMultipleDamage
end

---获取百分比列表
function SkillMultipleScopesDealMultipleDamageEffectParam:GetDamagePercent()
    return self._percent
end

---获取伤害计算公式ID
function SkillMultipleScopesDealMultipleDamageEffectParam:GetDamageFormulaID()
    return self._formulaID
end
