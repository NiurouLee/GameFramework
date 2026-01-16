--[[------------------------------------------------------------------------------------------
    SkillEffectPopStarResult : 消灭星星消除技能结果
]]
--------------------------------------------------------------------------------------------
require("skill_effect_result_base")

_class("SkillEffectPopStarResult", SkillEffectResultBase)
---@class SkillEffectPopStarResult: SkillEffectResultBase
SkillEffectPopStarResult = SkillEffectPopStarResult

function SkillEffectPopStarResult:Constructor(dataResult)
    self._popResult = dataResult
end

function SkillEffectPopStarResult:GetEffectType()
    return SkillEffectType.PopStar
end

function SkillEffectPopStarResult:GetDataPopStarResult()
    return self._popResult
end
