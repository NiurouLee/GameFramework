--[[------------------------------------------------------------------------------------------
    SkillEffectParamResetSingleColorGridElement : 重置单一颜色的格子
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")

----------------------------------------------------------------

_class("SkillEffectParamResetSingleColorGridElement", SkillEffectParamBase)
---@class SkillEffectParamResetSingleColorGridElement: SkillEffectParamBase
SkillEffectParamResetSingleColorGridElement = SkillEffectParamResetSingleColorGridElement
function SkillEffectParamResetSingleColorGridElement:Constructor(t)
	self._targetGridTypeList = t.targetGridTypeList
	self._excludeTrapIDList = t.excludeTrapIDList
end

function SkillEffectParamResetSingleColorGridElement:GetEffectType()
	return SkillEffectType.ResetSingleColorGridElement
end

function SkillEffectParamResetSingleColorGridElement:GetTargetGridTypeList()
	return self._targetGridTypeList
end

function SkillEffectParamResetSingleColorGridElement:GetExcludeTrapIDList()
	return self._excludeTrapIDList
end