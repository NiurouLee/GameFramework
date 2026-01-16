--[[
    EddyTransport = 20
]]
---@class SkillEffectCalc_AddCollectDropNum: Object
_class("SkillEffectCalc_AddCollectDropNum", Object)
SkillEffectCalc_AddCollectDropNum = SkillEffectCalc_AddCollectDropNum

function SkillEffectCalc_AddCollectDropNum:Constructor(world)
    ---@type MainWorld
    self._world = world
end

function SkillEffectCalc_AddCollectDropNum:DoSkillEffectCalculator(skillEffectCalcParam)
    local result = SkillAddCollectDropNumResult:New(1) --默认收集数增1
    return result
end
