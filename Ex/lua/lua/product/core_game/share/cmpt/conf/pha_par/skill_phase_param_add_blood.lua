--[[------------------------------------------------------------------------------------------
    SkillPhaseParam_AddBlood : 加血动画阶段
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_summon_everything"
---@class SkillPhaseParam_AddBlood: SkillPhaseParam_SummonEverything
_class("SkillPhaseParam_AddBlood", SkillPhaseParam_SummonEverything)
SkillPhaseParam_AddBlood = SkillPhaseParam_AddBlood

---@type SkillCommonParam
function SkillPhaseParam_AddBlood:Constructor(t)
    self._playerStepTime = t.playerStepTime or 0
end

function SkillPhaseParam_AddBlood:GetPhaseType()
    return SkillViewPhaseType.AddBlood
end

function SkillPhaseParam_AddBlood:GetPlayerStepTime()
    return self._playerStepTime
end
