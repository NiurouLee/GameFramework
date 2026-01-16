--[[
    Transformation = 71, --变身，改monsterID
]]
---@class SkillEffectCalc_Transformation: Object
_class("SkillEffectCalc_Transformation", Object)
SkillEffectCalc_Transformation = SkillEffectCalc_Transformation

function SkillEffectCalc_Transformation:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Transformation:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillTransformationParam
    local skillParam = skillEffectCalcParam.skillEffectParam
    return SkillTransformationEffectResult:New(
        skillEffectCalcParam.casterEntityID,
        skillParam:GetTargetMonsterID(),
        skillParam:GetUseHpPercent()
    )
end
