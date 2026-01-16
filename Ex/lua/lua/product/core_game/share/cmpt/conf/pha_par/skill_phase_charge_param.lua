--[[------------------------------------------------------------------------------------------
    SkillPhaseChargeParam
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseChargeParam: SkillPhaseParamBase
_class("SkillPhaseChargeParam", SkillPhaseParamBase)
SkillPhaseChargeParam = SkillPhaseChargeParam

function SkillPhaseChargeParam:Constructor(t)
    self._anim = t.anim --蓄力动画名
    self._delay = t.delay or 0 --特效出现延迟
    self._effIds = t.effIds --特效数组
end

function SkillPhaseChargeParam:GetCacheTable()
    local t = {}
    for i, v in ipairs(self._effIds) do
        table.insert(t, {Cfg.cfg_effect[v].ResPath, 1})
    end
    return t
end

function SkillPhaseChargeParam:GetPhaseType()
    return SkillViewPhaseType.Charge
end

function SkillPhaseChargeParam:GetAnim()
    return self._anim
end

function SkillPhaseChargeParam:GetDelay()
    return self._delay
end

function SkillPhaseChargeParam:GetEffIds()
    return self._effIds
end
