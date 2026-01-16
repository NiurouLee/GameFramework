--[[------------------------------------------------------------------------------------------
    MultipleDamageWithBuffLayer = 119, --根据施法者身上指定buff的层数，造成多次伤害
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamMultipleDamageWithBuffLayer", SkillDamageEffectParam)
---@class SkillEffectParamMultipleDamageWithBuffLayer: SkillDamageEffectParam
SkillEffectParamMultipleDamageWithBuffLayer = SkillEffectParamMultipleDamageWithBuffLayer

function SkillEffectParamMultipleDamageWithBuffLayer:Constructor(t)
    self._buffEffectType = t.buffEffectType --检查的buff
end

function SkillEffectParamMultipleDamageWithBuffLayer:GetEffectType()
    return SkillEffectType.MultipleDamageWithBuffLayer
end

function SkillEffectParamMultipleDamageWithBuffLayer:GetBuffEffectType()
    return self._buffEffectType
end
