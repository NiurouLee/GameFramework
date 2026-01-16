require("skill_effect_param_base")

---@class SkillEffectAlphaThrowTrapParam: SkillEffectParamBase
_class("SkillEffectAlphaThrowTrapParam", SkillEffectParamBase)
SkillEffectAlphaThrowTrapParam = SkillEffectAlphaThrowTrapParam

function SkillEffectAlphaThrowTrapParam:Constructor(t)
    self._trapID = t.trapID
    self._monsterClassID = t.monsterClassID
    self._basePercent = t.basePercent --首次伤害百分比
    self._afterPercent = t.afterPercent --后续伤害/首次伤害
    self._formulaID = t.formulaID --伤害公式ID
    self._buffID = t.buffID --骑乘机关在十字范围内的击晕BuffID
end

function SkillEffectAlphaThrowTrapParam:GetEffectType()
    return SkillEffectType.AlphaThrowTrap
end

function SkillEffectAlphaThrowTrapParam:GetTrapID()
    return self._trapID
end

function SkillEffectAlphaThrowTrapParam:GetMonsterClassID()
    return self._monsterClassID
end

function SkillEffectAlphaThrowTrapParam:GetBasePercent()
    return self._basePercent
end

function SkillEffectAlphaThrowTrapParam:GetAfterPercent()
    return self._afterPercent
end

function SkillEffectAlphaThrowTrapParam:GetFormulaID()
    return self._formulaID
end

function SkillEffectAlphaThrowTrapParam:GetBuffID()
    return self._buffID
end
