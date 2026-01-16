--[[
    AddRoundCount = 73,
]]
---@class SkillEffectCalc_AddRoundCount: Object
_class("SkillEffectCalc_AddRoundCount", Object)
SkillEffectCalc_AddRoundCount = SkillEffectCalc_AddRoundCount

function SkillEffectCalc_AddRoundCount:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AddRoundCount:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParamAddRound
    local skillAddRoundParam = skillEffectCalcParam.skillEffectParam
    local addRoundCount = skillAddRoundParam:GetAddRoundCount()
    ---@type MazeService
    local mazeService = self._world:GetService("Maze")
    mazeService:AddLight(addRoundCount)
end
