--[[------------------------------------------------------------------------------------------
    TurnToTargetChangeBodyAreaAndDir = 199, -- 朝向目标，中心点不变，修改自己身形和朝向，(n28蜘蛛3x2)
]] --------------------------------------------------------------------------------------------
require("skill_effect_param_base")
_class("SkillEffectParamTurnToTargetChangeBodyAreaAndDir", SkillEffectParamBase)
---@class SkillEffectParamTurnToTargetChangeBodyAreaAndDir: SkillEffectParamBase
SkillEffectParamTurnToTargetChangeBodyAreaAndDir = SkillEffectParamTurnToTargetChangeBodyAreaAndDir

function SkillEffectParamTurnToTargetChangeBodyAreaAndDir:Constructor(t)
    self._forceTurn = t.forceTurn or 0 --是否强行转向，默认0不转
end

function SkillEffectParamTurnToTargetChangeBodyAreaAndDir:GetEffectType()
    return SkillEffectType.TurnToTargetChangeBodyAreaAndDir
end

function SkillEffectParamTurnToTargetChangeBodyAreaAndDir:GetForceTurn()
    return self._forceTurn
end
