--[[
    SkillEffectCalc_CreateDestroyGrid = 24
]]
require("calc_base")

---@class SkillEffectCalc_CreateDestroyGrid: SkillEffectCalc_Base
_class("SkillEffectCalc_CreateDestroyGrid", SkillEffectCalc_Base)
SkillEffectCalc_CreateDestroyGrid = SkillEffectCalc_CreateDestroyGrid

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_CreateDestroyGrid:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_CreateDestroyGrid
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    local isCreate = skillEffectParam:GetIsCreate()
    local range = skillEffectCalcParam:GetSkillRange()
    ---@type SkillEffectResult_CreateDestroyGrid
    local result = SkillEffectResult_CreateDestroyGrid:New(isCreate, range)
    return result
end
