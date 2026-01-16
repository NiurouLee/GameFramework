----------------------------------------------------------------
require "skill_damage_effect_param"

_class("SkillEffectParamRandomCountDamageSameHalf", SkillDamageEffectParam)
---@class SkillEffectParamRandomCountDamageSameHalf: SkillDamageEffectParam
SkillEffectParamRandomCountDamageSameHalf = SkillEffectParamRandomCountDamageSameHalf

function SkillEffectParamRandomCountDamageSameHalf:Constructor(t)
    ---目标被重复打击每次衰减的伤害系数
    self._dampPer = t.dampPer
    ---辅助调整percent
    self._percentAdd = t.percentAdd or 0
    self._selTargetLoop = t.selTargetLoop or false --循环选敌
    self._damageRandomCount = t.damageRandomCount --随机攻击次数
end

function SkillEffectParamRandomCountDamageSameHalf:GetEffectType()
    return SkillEffectType.RandomCountDamageSameHalf
end
function SkillEffectParamRandomCountDamageSameHalf:GetPercentAdd()
    return self._percentAdd
end
function SkillEffectParamRandomCountDamageSameHalf:GetDampPercent()
    return self._dampPer
end
function SkillEffectParamRandomCountDamageSameHalf:GetIsSelTargetLoop()
    return self._selTargetLoop
end
function SkillEffectParamRandomCountDamageSameHalf:GetDamageRandomCount()
    return self._damageRandomCount
end
----------------------------------------------------------------
