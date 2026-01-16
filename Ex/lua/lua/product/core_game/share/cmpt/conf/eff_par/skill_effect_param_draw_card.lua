--[[------------------------------------------------------------------------------------------
    DrawCard = 166, --抽卡 （光灵杰诺）
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamDrawCard", SkillEffectParamBase)
---@class SkillEffectParamDrawCard: SkillEffectParamBase
SkillEffectParamDrawCard = SkillEffectParamDrawCard

function SkillEffectParamDrawCard:Constructor(t)
end

function SkillEffectParamDrawCard:GetEffectType()
    return SkillEffectType.DrawCard
end
