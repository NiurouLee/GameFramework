--[[------------------------------------------------------------------------------------------
    SkillPullAroundEffectParam : 拉到周围技能效果参数
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillPullAroundEffectParam: SkillEffectParamBase
_class("SkillPullAroundEffectParam", SkillEffectParamBase)
SkillPullAroundEffectParam = SkillPullAroundEffectParam

function SkillPullAroundEffectParam:Constructor()
end

function SkillPullAroundEffectParam:GetEffectType()
    return SkillEffectType.PullAround
end
