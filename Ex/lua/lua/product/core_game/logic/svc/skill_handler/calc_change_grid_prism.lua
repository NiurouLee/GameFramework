--[[
    棱镜修改棱镜信息
]]
---@class SkillEffectCalc_ChangeGridPrism: Object
_class("SkillEffectCalc_ChangeGridPrism", Object)
SkillEffectCalc_ChangeGridPrism = SkillEffectCalc_ChangeGridPrism

function SkillEffectCalc_ChangeGridPrism:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_ChangeGridPrism:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillChangeGridPrismParam
    local skillParam = skillEffectCalcParam.skillEffectParam
    local change = skillParam:GetChangeType()
    local gridEffectType = skillParam:GetGridEffectType()
    local centerPos = skillEffectCalcParam.centerPos
    ---@type BoardComponent
    local boardCmpt = self._world:GetBoardEntity():Board()

    if change == "add" then
        boardCmpt:AddPrismPiece(centerPos, skillEffectCalcParam.casterEntityID)
        boardCmpt:SetPrismPieceEffectType(centerPos, gridEffectType)
    elseif change == "remove" then
        boardCmpt:RemovePrismPiece(centerPos, skillEffectCalcParam.casterEntityID)
        boardCmpt:SetPrismPieceEffectType(centerPos, nil)
    end

    return SkillEffectResultChangeGridPrism:New()
end
