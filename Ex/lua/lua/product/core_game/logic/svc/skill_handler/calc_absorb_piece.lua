--[[
    AbsorbPiece = 10, --吸收格子
]]
---@class SkillEffectCalc_AbsorbPiece: Object
_class("SkillEffectCalc_AbsorbPiece", Object)
SkillEffectCalc_AbsorbPiece = SkillEffectCalc_AbsorbPiece

function SkillEffectCalc_AbsorbPiece:Constructor(world)
    ---@type MainWorld
    self._world = world
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_AbsorbPiece:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillAbsorbPieceEffectParam
    local skillAbsorbPieceEffectParam = skillEffectCalcParam.skillEffectParam
    local targetPieceType = skillAbsorbPieceEffectParam:GetPieceType()
    local targetPieceCount = skillAbsorbPieceEffectParam:GetPieceCount()

    local scopeList = skillEffectCalcParam.skillRange
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local centerPos = attacker:GridLocation():GetGridPos()

    ---@type BoardServiceLogic
    local boardServiceLogic = self._world:GetService("BoardLogic")
    local absorbPieceList =
        boardServiceLogic:FindPieceElementByTypeCountAndCenterFromParam(
        centerPos,
        targetPieceType,
        targetPieceCount,
        scopeList
    )
    ---@type SkillAbsorbPieceEffectResult
    local absorbResult = SkillAbsorbPieceEffectResult:New()
    absorbResult:SetAbsorbPieceList(absorbPieceList)
    local gameFsmCmpt = self._world:GameFSM()
    local gameFsmStateID = gameFsmCmpt:CurStateID()
    if gameFsmStateID ~= GameStateID.PreviewActiveSkill then
        local newGridPosList = boardServiceLogic:SupplyPieceList(absorbPieceList)
        absorbResult:SetNewPieceList(newGridPosList)
    end
    return absorbResult
end
