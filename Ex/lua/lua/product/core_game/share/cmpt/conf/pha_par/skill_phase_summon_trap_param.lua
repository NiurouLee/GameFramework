--[[------------------------------------------------------------------------------------------
    SkillPhaseSummonTrapParam : 召唤陷阱动画阶段
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseSummonTrapParam: SkillPhaseParamBase
_class("SkillPhaseSummonTrapParam", SkillPhaseParamBase)
SkillPhaseSummonTrapParam = SkillPhaseSummonTrapParam

---@type SkillCommonParam
function SkillPhaseSummonTrapParam:Constructor(t)
    self._showTimeDelay = t.showTimeDelay or 0
end

function SkillPhaseSummonTrapParam:GetCacheTable()
    local t = {}
    return t
end

function SkillPhaseSummonTrapParam:GetPhaseType()
    return SkillViewPhaseType.SummonTrap
end

function SkillPhaseSummonTrapParam:GetShowTimeDelay()
    return self._showTimeDelay
end
