--[[------------------------------------------------------------------------------------------
    改变自身属性技能结果
]] --------------------------------------------------------------------------------------------

_class("SkillEffectResultChangeElement", SkillEffectResultBase)
---@class SkillEffectResultChangeElement: SkillEffectResultBase
SkillEffectResultChangeElement = SkillEffectResultChangeElement

function SkillEffectResultChangeElement:Constructor(target, elementType)
    self.target = target
    self.elementType = elementType
end
function SkillEffectResultChangeElement:GetEffectType()
    return SkillEffectType.ChangeElement
end

function SkillEffectResultChangeElement:GetTarget()
    return self.target
end

function SkillEffectResultChangeElement:GetElementType()
    return self.elementType
end
