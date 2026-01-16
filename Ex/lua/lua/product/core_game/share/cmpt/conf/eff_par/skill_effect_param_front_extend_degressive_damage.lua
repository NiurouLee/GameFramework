--[[------------------------------------------------------------------------------------------
    FrontExtendDegressiveDamage = 114, ---选取的第一个点为中心，选取第二个点作为方向，直线到版边。中间如果遇到指定机关，根据规则做扩展范围，扩展格子伤害递减（普律玛主动技）

]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectParamFrontExtendDegressiveDamage: SkillEffectParamBase
_class("SkillEffectParamFrontExtendDegressiveDamage", SkillEffectParamBase)
SkillEffectParamFrontExtendDegressiveDamage = SkillEffectParamFrontExtendDegressiveDamage

function SkillEffectParamFrontExtendDegressiveDamage:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式

    self._effectParam = t.effectParam --计算范围的参数
end

function SkillEffectParamFrontExtendDegressiveDamage:GetEffectType()
    return SkillEffectType.FrontExtendDegressiveDamage
end

function SkillEffectParamFrontExtendDegressiveDamage:GetDamageFormulaID()
    return self._formulaID
end

--计算前的伤害系数，范围里的基础数值
function SkillEffectParamFrontExtendDegressiveDamage:GetBaseDamagePercent()
    return self._percent[1]
end

--计算后的伤害系数，计算公式实际用到的参数
function SkillEffectParamFrontExtendDegressiveDamage:GetDamagePercent()
    return self._damagePercent or self._percent
end

function SkillEffectParamFrontExtendDegressiveDamage:SetDamagePercent(damagePercent)
    self._damagePercent = damagePercent
end

function SkillEffectParamFrontExtendDegressiveDamage:GetEffectParam()
    return self._effectParam
end
