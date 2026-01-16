--[[------------------------------------------------------------------------------------------
    技能结果
]] --------------------------------------------------------------------------------------------

_class("SkillAddComboNumEffectResult", SkillEffectResultBase)
---@class SkillAddComboNumEffectResult: SkillEffectResultBase
SkillAddComboNumEffectResult = SkillAddComboNumEffectResult

function SkillAddComboNumEffectResult:Constructor()
end
function SkillAddComboNumEffectResult:GetEffectType()
    return SkillEffectType.AddComboNum
end
