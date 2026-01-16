
----------------------------------------------------------------
require "skill_damage_effect_param"


_class("SkillEffectParamDamageSamePosReduce", SkillDamageEffectParam)
---@class SkillEffectParamDamageSamePosReduce: SkillDamageEffectParam
SkillEffectParamDamageSamePosReduce = SkillEffectParamDamageSamePosReduce

function SkillEffectParamDamageSamePosReduce:Constructor(t)
    self._finalEffectType = t.finalEffectType
    ---格子被重复打击每次衰减的伤害系数
    self._dampPer = t.dampPer
    self._req = t.req or 20
end

function SkillEffectParamDamageSamePosReduce:GetEffectType()
    return SkillEffectType.DamageSamePosReduce
end

function SkillEffectParamDamageSamePosReduce:GetFinalEffectType()
    return self._finalEffectType
end
function SkillEffectParamDamageSamePosReduce:GetDampPercent()
    return self._dampPer
end

----------------------------------------------------------------