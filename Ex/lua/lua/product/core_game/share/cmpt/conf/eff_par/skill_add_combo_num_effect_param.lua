--[[------------------------------------------------------------------------------------------
    AddComboNum = 93, ---增加连线普攻combo数
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillAddComboNumEffectParam", SkillEffectParamBase)
---@class SkillAddComboNumEffectParam: SkillEffectParamBase
SkillAddComboNumEffectParam = SkillAddComboNumEffectParam

function SkillAddComboNumEffectParam:Constructor(t)
end

function SkillAddComboNumEffectParam:GetEffectType()
    return SkillEffectType.AddComboNum
end
