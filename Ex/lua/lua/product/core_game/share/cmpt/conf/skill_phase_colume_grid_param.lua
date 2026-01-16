--[[------------------------------------------------------------------------------------------
    SkillPhaseColumeGridParam : 单列波浪形技能参数
]] --------------------------------------------------------------------------------------------
require "skill_phase_param_base"
---@class SkillPhaseColumeGridParam
_class("SkillPhaseColumeGridParam", SkillPhaseParamBase)
SkillPhaseColumeGridParam = SkillPhaseColumeGridParam
function SkillPhaseColumeGridParam:Constructor(t)
    self.gridEffectID = t.gridEffectID
    self.columnInternalTime = t.columnInternalTime
    self.hitAnimName = t.hitAnimName
    self.hitEffectID = t.hitEffectID
end

function SkillPhaseColumeGridParam:GetPhaseType()
    return SkillViewPhaseType.ColumeWaveGrid
end
