require("skill_effect_param_base")

---@class SkillEffectConvertOccupiedGridElementParam : SkillEffectParamBase
_class("SkillEffectConvertOccupiedGridElementParam", SkillEffectParamBase)
SkillEffectConvertOccupiedGridElementParam = SkillEffectConvertOccupiedGridElementParam

function SkillEffectConvertOccupiedGridElementParam:Constructor(t)
    --目标格子的颜色
    self.targetGridElement = t.targetGridElement
    --单个目标最大转色数量，随机选中
    self.maxPosPerTarget = t.maxPosPerTarget
    --优先转色非目标颜色，当剩余颜色都是目标颜色的时候，也会转色目标颜色
    self.priorityTarget = t.priorityTarget
    self.trapID = t.trapID
end

function SkillEffectConvertOccupiedGridElementParam:GetEffectType()
    return SkillEffectType.ConvertOccupiedGridElement
end

function SkillEffectConvertOccupiedGridElementParam:GetTargetGridElement()
    return self.targetGridElement
end

function SkillEffectConvertOccupiedGridElementParam:GetMaxPosPerTarget()
    return self.maxPosPerTarget
end

function SkillEffectConvertOccupiedGridElementParam:GetPriorityTarget()
    return self.priorityTarget
end
function SkillEffectConvertOccupiedGridElementParam:GetTrapID()
    return self.trapID
end