require("pick_up_policy_base")

_class("PickUpPolicy_PetZhongxuMain", PickUpPolicy_Base)
---@class PickUpPolicy_PetZhongxuMain: PickUpPolicy_Base
PickUpPolicy_PetZhongxuMain = PickUpPolicy_PetZhongxuMain

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetZhongxuMain:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetZhongxuMain(petEntity, casterPos, validPosIdxList)
    return pickPosList, atkPosList, targetIds, extraParam
end
--仲胥 1技能 选离队伍最近的非火格子（无怪、可召唤机关）召唤机关
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetZhongxuMain:_CalPickPosPolicy_PetZhongxuMain(petEntity, casterPos, validPosIdxList)
    local env = self:_GetPickUpPolicyEnv()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local casterPosIndex = self:_Pos2Index(casterPos)
    local firstPickPos
    local blackFistEnemyPos = nil
    if self._world:MatchType() == MatchType.MT_BlackFist then
        if petEntity:HasPet() then
            local enemy = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
            blackFistEnemyPos = enemy:GetGridPosition()
        end
    end
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local color = env.BoardPosPieces[posIdx]
            if color and color ~= PieceType.Red then
                if self._world:MatchType() == MatchType.MT_BlackFist then
                    if blackFistEnemyPos ~= pos then
                        firstPickPos = pos
                        break
                    end
                else
                    local isHasMonster, monsterID = utilScopeSvc:IsPosHasMonster(pos)
                    if not isHasMonster then
                        firstPickPos = pos
                        break
                    end
                end
            end
        end
    end
    if firstPickPos then
        return { firstPickPos }, { firstPickPos }, {}
    else
        return {}, {}, {}
    end
end