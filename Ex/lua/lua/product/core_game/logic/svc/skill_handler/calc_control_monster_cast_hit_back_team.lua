--[[
    ControlMonsterCastHitBackTeam = 217, -- 控制目标怪物施法击退队伍
]]
---@class SkillEffectCalc_ControlMonsterCastHitBackTeam : SkillEffectCalc_Base
_class("SkillEffectCalc_ControlMonsterCastHitBackTeam", SkillEffectCalc_Base)
SkillEffectCalc_ControlMonsterCastHitBackTeam = SkillEffectCalc_ControlMonsterCastHitBackTeam

function SkillEffectCalc_ControlMonsterCastHitBackTeam:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ControlMonsterCastHitBackTeam:DoSkillEffectCalculator(skillEffectCalcParam)
    self._skillEffectCalcParam = skillEffectCalcParam
    ---@type SkillEffectParamControlMonsterCastHitBackTeam
    local skillParam = skillEffectCalcParam.skillEffectParam
end
