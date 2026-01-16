require("skill_effect_param_base")
----------------------------------------------------------------
---@class SkillEffectParam_MultiRangeAttack: SkillEffectParamBase
_class("SkillEffectParam_MultiRangeAttack", SkillEffectParamBase)
SkillEffectParam_MultiRangeAttack = SkillEffectParam_MultiRangeAttack

function SkillEffectParam_MultiRangeAttack:Constructor(t)
    self._percent = t.percent
    self._formulaID = t.formulaID
    if t.vampire ~= nil then
        self._vampire = t.vampire
    else
        self._vampire = nil
    end
end

function SkillEffectParam_MultiRangeAttack:GetEffectType()
    return SkillEffectType.MultiRangeAttack
end

---获取百分比列表
function SkillEffectParam_MultiRangeAttack:GetDamagePercent()
    return self._percent
end

---获取伤害计算公式ID
function SkillEffectParam_MultiRangeAttack:GetDamageFormulaID()
    return self._formulaID
end

--吸血参数
function SkillEffectParam_MultiRangeAttack:GetVampire()
    return self._vampire
end
