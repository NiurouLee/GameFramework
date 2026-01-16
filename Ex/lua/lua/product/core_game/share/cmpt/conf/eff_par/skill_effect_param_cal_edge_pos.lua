--[[----------------------------------------------------------------
    SkillEffectParamCalEdgePos : 计算边界位置
--]] ----------------------------------------------------------------
require("skill_effect_param_base")
---@class SkillEffectParamCalEdgePos:SkillEffectParamBase
_class("SkillEffectParamCalEdgePos", SkillEffectParamBase)
SkillEffectParamCalEdgePos = SkillEffectParamCalEdgePos

function SkillEffectParamCalEdgePos:Constructor(t)
    self.targetType = t.targetType --1:敌方2:自己
end

function SkillEffectParamCalEdgePos:GetEffectType()
    return SkillEffectType.CalEdgePos
end

---获取目标类型
function SkillEffectParamCalEdgePos:GetTargetType()
    return self.targetType
end
