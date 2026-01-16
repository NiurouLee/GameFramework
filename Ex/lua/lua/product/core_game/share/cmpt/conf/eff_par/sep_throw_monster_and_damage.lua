require("skill_effect_param_base")

---@class SkillEffectThrowMonsterAndDamageParam: SkillEffectParamBase
_class("SkillEffectThrowMonsterAndDamageParam", SkillEffectParamBase)
SkillEffectThrowMonsterAndDamageParam = SkillEffectThrowMonsterAndDamageParam

function SkillEffectThrowMonsterAndDamageParam:Constructor(t)
    self._monsterClassID = t.monsterClassID
    self._basePercent = t.basePercent --基础伤害百分比
    self._addPercent = t.addPercent --附加伤害百分比（数量相关）
    self._formulaID = t.formulaID --伤害公式ID
end

function SkillEffectThrowMonsterAndDamageParam:GetEffectType()
    return SkillEffectType.ThrowMonsterAndDamage
end

function SkillEffectThrowMonsterAndDamageParam:GetMonsterClassID()
    return self._monsterClassID
end

function SkillEffectThrowMonsterAndDamageParam:GetBasePercent()
    return self._basePercent
end

function SkillEffectThrowMonsterAndDamageParam:GetAddPercent()
    return self._addPercent
end

function SkillEffectThrowMonsterAndDamageParam:GetFormulaID()
    return self._formulaID
end
