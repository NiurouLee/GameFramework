require("skill_effect_param_base")

---@class SkillEffectParam_DimensionTransport : SkillEffectParamBase
_class("SkillEffectParam_DimensionTransport", SkillEffectParamBase)
SkillEffectParam_DimensionTransport = SkillEffectParam_DimensionTransport

function SkillEffectParam_DimensionTransport:Constructor(t)
end

function SkillEffectParam_DimensionTransport:GetEffectType()
    return SkillEffectType.DimensionTransport
end
