--[[----------------------------------------------------------------
    2020-03-27 韩玉信添加
    2020-06-22 于昌弘重做印记附加之类伤害
    SkillEffectParam_StampDamage : 印记附加伤害
--]]----------------------------------------------------------------

----------------------------------------------------------------
require "skill_damage_effect_param"

---@class SkillEffectParam_StampDamage: SkillDamageEffectParam
_class("SkillEffectParam_StampDamage", SkillDamageEffectParam)
SkillEffectParam_StampDamage = SkillEffectParam_StampDamage

function SkillEffectParam_StampDamage:Constructor(t)
    self._addDamageByStamp = t.addDamageByStamp
    self._buffId = t.buffId
end

function SkillEffectParam_StampDamage:GetEffectType()
    return SkillEffectType.StampDamage
end

function SkillEffectParam_StampDamage:GetBuffID()
    return self._buffId
end

function SkillEffectParam_StampDamage:GetAddDamageByStamp()
    return self._addDamageByStamp
end
----------------------------------------------------------------