require "skill_phase_param_base"
---@class SkillPhasePlayEffectAtGridParam: Object
_class("SkillPhasePlayEffectAtGridParam", SkillPhaseParamBase)
SkillPhasePlayEffectAtGridParam = SkillPhasePlayEffectAtGridParam


---@type SkillCommonParam
function SkillPhasePlayEffectAtGridParam:Constructor(t)
	self._gridEffectList = t;
end

function SkillPhasePlayEffectAtGridParam:GetCacheTable()
	local effectList = {}
	for k, v in ipairs(self._gridEffectList) do
		table.insert(effectList,{Cfg.cfg_effect[v.effectID].ResPath, 1} )
	end
	return effectList
end

function SkillPhasePlayEffectAtGridParam:GetPhaseType()
	return SkillViewPhaseType.PlayEffectAtGrid
end

function SkillPhasePlayEffectAtGridParam:GetGirdEffectList()
	return self._gridEffectList
end
