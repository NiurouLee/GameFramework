--[[------------------------------------------------------------------------------------------
    SkillPhaseImpactAnimationParam
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseImpactAnimationParam: Object
_class("SkillPhaseImpactAnimationParam", SkillPhaseParamBase)
SkillPhaseImpactAnimationParam = SkillPhaseImpactAnimationParam

---@param showDelay string 出现延迟ms
function SkillPhaseImpactAnimationParam:Constructor(t)
    self._showDelay = t.showDelay
end

function SkillPhaseImpactAnimationParam:GetCacheTable()
    local t = {}
    return t
end

function SkillPhaseImpactAnimationParam:GetPhaseType()
    return SkillViewPhaseType.ImpactAnimation
end

function SkillPhaseImpactAnimationParam:GetShowDelay()
    return self._showDelay
end
