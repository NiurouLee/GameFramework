--[[
    ConvertGridElement = 4, --转色
]]
---@class SkillEffectCalc_ConvertGridElement: Object
_class("SkillEffectCalc_ConvertGridElement", Object)
SkillEffectCalc_ConvertGridElement = SkillEffectCalc_ConvertGridElement

function SkillEffectCalc_ConvertGridElement:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ConvertGridElement:DoSkillEffectCalculator(skillEffectCalcParam)
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    return self._skillEffectService:_DoCalcSkillConvertGridElementEffect(
        skillEffectCalcParam.skillEffectParam,
        skillEffectCalcParam.skillRange,
        casterEntity
    )
end
