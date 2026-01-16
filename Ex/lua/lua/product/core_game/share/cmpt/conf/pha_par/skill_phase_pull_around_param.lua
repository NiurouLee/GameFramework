--[[------------------------------------------------------------------------------------------
    SkillPhasePullAroundParam : 牵引效果表现参数
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhasePullAroundParam: Object
_class("SkillPhasePullAroundParam", SkillPhaseParamBase)
SkillPhasePullAroundParam = SkillPhasePullAroundParam

---@type SkillCommonParam
function SkillPhasePullAroundParam:Constructor(t)
    self._hitAnimationName = t.hitAnimationName
    self._moveSpeed = t.moveSpeed
end

function SkillPhasePullAroundParam:GetCacheTable()
    local t = {}
    return t
end

function SkillPhasePullAroundParam:GetPhaseType()
    return SkillViewPhaseType.PullAround
end

function SkillPhasePullAroundParam:GetHitAnimationName()
    return self._hitAnimationName
end

function SkillPhasePullAroundParam:GetMoveSpeed()
    return self._moveSpeed
end