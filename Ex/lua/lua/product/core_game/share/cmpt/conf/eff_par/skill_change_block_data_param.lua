--[[------------------------------------------------------------------------------------------
    SkillChangeBlockDataParam : 修改阻挡
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")

_class("SkillChangeBlockDataParam", SkillEffectParamBase)
---@class SkillChangeBlockDataParam: SkillEffectParamBase
SkillChangeBlockDataParam = SkillChangeBlockDataParam

function SkillChangeBlockDataParam:Constructor(t)
    self._change = t.change --'push' 保存 或 'pop' 还原
end

function SkillChangeBlockDataParam:GetEffectType()
    return SkillEffectType.ChangeBlockData
end

function SkillChangeBlockDataParam:GetChangeType()
    return self._change
end
