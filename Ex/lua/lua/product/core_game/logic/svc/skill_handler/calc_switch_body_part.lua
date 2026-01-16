--[[
    SwitchBodyPart = 132, ---根据配置切换外形显隐
]]
---@class SkillEffectCalc_SwitchBodyPart: Object
_class("SkillEffectCalc_SwitchBodyPart", Object)
SkillEffectCalc_SwitchBodyPart = SkillEffectCalc_SwitchBodyPart

function SkillEffectCalc_SwitchBodyPart:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_SwitchBodyPart:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamSwitchBodyPart
    local effParam = skillEffectCalcParam.skillEffectParam
    local showID = effParam:GetShowID()
    local hideID = effParam:GetHideID()

    local result = SkillEffectResultSwitchBodyPart:New(showID, hideID)

    return result
end
