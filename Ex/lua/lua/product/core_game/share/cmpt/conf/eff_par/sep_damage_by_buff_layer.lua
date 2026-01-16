require("skill_effect_param_base")
require("skill_damage_effect_param")
---@class SkillEffectDamageByBuffLayerParam : SkillDamageEffectParam
_class("SkillEffectDamageByBuffLayerParam", SkillDamageEffectParam)
SkillEffectDamageByBuffLayerParam = SkillEffectDamageByBuffLayerParam

function SkillEffectDamageByBuffLayerParam:Constructor(t)
    self._maxAddPercent = t.maxAddPercent --最大可增加的伤害系数
    self._buffEffectType = t.buffEffectType --增加伤害系数的Buff效果类型
    self._maxLayerCount = t.maxLayerCount --最大Buff层数，伤害系数计算式的分母
    self._power = t.power or 1 --层数百分比的幂
end

function SkillEffectDamageByBuffLayerParam:GetEffectType()
    return SkillEffectType.DamageByBuffLayer
end

function SkillEffectDamageByBuffLayerParam:GetMaxAddPercent()
    return self._maxAddPercent
end

function SkillEffectDamageByBuffLayerParam:GetAddPercentBuffEffectType()
    return self._buffEffectType
end

function SkillEffectDamageByBuffLayerParam:GetMaxLayerCount()
    return self._maxLayerCount
end

function SkillEffectDamageByBuffLayerParam:GetDamagePower()
    return self._power
end
