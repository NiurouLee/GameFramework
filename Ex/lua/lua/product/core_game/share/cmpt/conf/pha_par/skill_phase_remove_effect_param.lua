--[[------------------------------------------------------------------------------------------
    SkillPhaseRemoveEffectParam : 移除特效技能参数
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseRemoveEffectParam
_class("SkillPhaseRemoveEffectParam", SkillPhaseParamBase)
SkillPhaseRemoveEffectParam = SkillPhaseRemoveEffectParam
function SkillPhaseRemoveEffectParam:Constructor(t)    
    self._effectIDList = t.effectIDList
end

function SkillPhaseRemoveEffectParam:GetPhaseType()
    return SkillViewPhaseType.RemoveEffect
end

--获取需要缓存的prefab
function SkillPhaseRemoveEffectParam:GetCacheTable()
    return {}
end

function SkillPhaseRemoveEffectParam:GetEffectIDList()
    return self._effectIDList
end
