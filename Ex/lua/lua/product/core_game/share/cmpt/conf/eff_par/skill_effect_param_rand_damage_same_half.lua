
----------------------------------------------------------------
require "skill_damage_effect_param"


_class("SkillEffectParamRandDamageSameHalf", SkillDamageEffectParam)
---@class SkillEffectParamRandDamageSameHalf: SkillDamageEffectParam
SkillEffectParamRandDamageSameHalf = SkillEffectParamRandDamageSameHalf

function SkillEffectParamRandDamageSameHalf:Constructor(t)
	self._damageCount = t.damageCount
	---目标被重复打击每次衰减的伤害系数
	self._dampPer = t.dampPer
	---辅助调整percent
	self._percentAdd = t.percentAdd or 0
	self._selTargetLoop = t.selTargetLoop or false--循环选敌
    self._damageRandomCount = t.damageRandomCount --随机攻击次数
    self._repeatAllSameHalf = t.repeatAllSameHalf --米洛斯 两次目标相同，则两次伤害都是衰减一次后
	self._keepDampList = t.keepDampList or false --是否记录伤害列表，直到其他逻辑清除数据为止
end

function SkillEffectParamRandDamageSameHalf:GetEffectType()
	return SkillEffectType.RandDamageSameHalf
end

function SkillEffectParamRandDamageSameHalf:GetDamageCount()
	return self._damageCount
end
function SkillEffectParamRandDamageSameHalf:GetPercentAdd()
	return self._percentAdd
end
function SkillEffectParamRandDamageSameHalf:GetDampPercent()
	return self._dampPer
end
function SkillEffectParamRandDamageSameHalf:GetIsSelTargetLoop()
	return self._selTargetLoop
end
function SkillEffectParamRandDamageSameHalf:GetDamageRandomCount()
    return self._damageRandomCount
end
function SkillEffectParamRandDamageSameHalf:IsRepeatAllSameHalf()
    return self._repeatAllSameHalf
end
function SkillEffectParamRandDamageSameHalf:IsKeepDampList()
	return self._keepDampList
end
----------------------------------------------------------------