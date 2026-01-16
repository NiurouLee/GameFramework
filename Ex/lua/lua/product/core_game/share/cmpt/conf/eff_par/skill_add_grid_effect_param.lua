--[[------------------------------------------------------------------------------------------
    SkillAddGridEffectParam : 技能转换特殊格子效果参数
]]
--------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillAddGridEffectParam: SkillEffectParamBase
_class("SkillAddGridEffectParam", SkillEffectParamBase)
SkillAddGridEffectParam = SkillAddGridEffectParam

function SkillAddGridEffectParam:Constructor(t)
    self._targetGridEffectType = t.gridEffectType
    self._gridConvertType = t.gridConvertType
    self._summonTrap = t.summonTrap or BattleConst.PrismTrapID
    ---当格子为禁止转色的万色格子时，忽略转色
    self._ignoreConvertForAny = t.ignoreConvertForAny
end

function SkillAddGridEffectParam:GetEffectType()
    return SkillEffectType.AddGridEffect
end

function SkillAddGridEffectParam:GetTargetGridEffectType()
    return self._targetGridEffectType
end

function SkillAddGridEffectParam:GetGridConvertType()
    return self._gridConvertType
end

function SkillAddGridEffectParam:GetSummonTrap()
    return self._summonTrap
end

function SkillAddGridEffectParam:GetIgnoreConvertForAny()
    return self._ignoreConvertForAny
end
