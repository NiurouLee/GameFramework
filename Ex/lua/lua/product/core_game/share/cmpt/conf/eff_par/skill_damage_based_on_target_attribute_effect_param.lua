--[[------------------------------------------------------------------------------------------
    SkillDamageBasedOnTargetAttributeEffectParam : 技能伤害效果参数
]] --------------------------------------------------------------------------------------------

require("skill_effect_param_base")

_class("SkillDamageBasedOnTargetAttributeEffectParam", SkillEffectParamBase)
---@class SkillDamageBasedOnTargetAttributeEffectParam: SkillEffectParamBase
SkillDamageBasedOnTargetAttributeEffectParam = SkillDamageBasedOnTargetAttributeEffectParam

function SkillDamageBasedOnTargetAttributeEffectParam:Constructor(t)
    self._percent = t.percent --伤害系数
    self._formulaID = t.formulaID --伤害公式

    self._target = t.target or "SkillTarget" --目标实体
    self._targetAttribute = t.targetAttribute --目标实体的属性
    self._compare = t.compare or "Self" --对比实体
    self._compareAttribute = t.compareAttribute --对比实体的属性
    self._compareParam = t.compareParam or 1 --对比属性的参数

    self._compareSymbol = t.compareSymbol --对比的符号

    self._ownerBuffEffect = t.ownerBuffEffect --施法者是否拥有指定buff，不写默认不判断

    self._preDamageStageIndex = t.preDamageStageIndex --前置伤害阶段，如果当前攻击的目标没有在前置伤害阶段里，不继续判断。不写默认不判断
end
---目标实体
function SkillDamageBasedOnTargetAttributeEffectParam:GetTarget()
    return self._target
end
---目标实体的属性
function SkillDamageBasedOnTargetAttributeEffectParam:GetTargetAttribute()
    return self._targetAttribute
end
---对比实体
function SkillDamageBasedOnTargetAttributeEffectParam:GetCompare()
    return self._compare
end
---对比实体的属性
function SkillDamageBasedOnTargetAttributeEffectParam:GetCompareAttribute()
    return self._compareAttribute
end
---对比属性的参数
function SkillDamageBasedOnTargetAttributeEffectParam:GetCompareParam()
    return self._compareParam
end
---对比的符号
function SkillDamageBasedOnTargetAttributeEffectParam:GetCompareSymbol()
    return self._compareSymbol
end
function SkillDamageBasedOnTargetAttributeEffectParam:GetOwnerBuffEffect()
    return self._ownerBuffEffect
end

function SkillDamageBasedOnTargetAttributeEffectParam:GetPreDamageStageIndex()
    return self._preDamageStageIndex
end

function SkillDamageBasedOnTargetAttributeEffectParam:GetEffectType()
    return SkillEffectType.DamageBasedOnTargetAttribute
end

---获取百分比列表
function SkillDamageBasedOnTargetAttributeEffectParam:GetDamagePercent()
    return self._percent
end

---获取伤害计算公式ID
function SkillDamageBasedOnTargetAttributeEffectParam:GetDamageFormulaID()
    return self._formulaID
end
