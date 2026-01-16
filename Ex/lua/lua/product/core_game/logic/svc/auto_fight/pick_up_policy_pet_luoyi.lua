require("pick_up_policy_base")

_class("PickUpPolicy_PetLuoYi", PickUpPolicy_Base)
---@class PickUpPolicy_PetLuoYi: PickUpPolicy_Base
PickUpPolicy_PetLuoYi = PickUpPolicy_PetLuoYi

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetLuoYi:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position


    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetLuoYi(petEntity, activeSkillID, casterPos, validPosIdxList)
    return pickPosList, atkPosList, targetIds, extraParam
end
--罗伊：范围内最近的非黄色格子，格子上是否有指定机关会影响能量消耗
---罗伊三觉后主动技根据是否到了自己的转色机关，消耗不同
---从玩家位置由近及远找非黄色格子，如果需要判断消耗（三觉后），则还有根据选中位置是否有转色机关计算实际消耗，并判断
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetLuoYi:_CalPickPosPolicy_PetLuoYi(petEntity, activeSkillID, casterPos, validPosIdxList)
    local env = self:_GetPickUpPolicyEnv()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local ringMax = boardService:GetCurBoardRingMax()
    ---@type UtilDataServiceShare
    local udsvc = self._world:GetService("UtilData")

    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local casterPosIndex = self:_Pos2Index(casterPos)

    local needCheckPower = false
    local powerIfNoTrap
    local tarTrapId
    local extraParam = skillConfigData:GetSkillTriggerExtraParam()
    if extraParam then
        if extraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap] then
            needCheckPower = true
            powerIfNoTrap = extraParam[SkillTriggerTypeExtraParam.PickPosNoCfgTrap]
            local pickType = skillConfigData:GetSkillPickType()
            if pickType == SkillPickUpType.PickDiffPowerInstruction then
                local pickParams = skillConfigData:GetSkillPickParam()
                tarTrapId = pickParams[3]
            end
        end
    end
    local legendPower = 0
    if needCheckPower then
        ---@type AttributesComponent
        local attributeCmpt = petEntity:Attributes()
        if attributeCmpt then
            legendPower = attributeCmpt:GetAttribute("LegendPower")
        end
    end

    local pickExtraParam = {}
    local firstPickPos
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            local color = env.BoardPosPieces[posIdx]
            if color and color ~= PieceType.Yellow then
                --判断机关和能量
                if needCheckPower then
                    local bPickTrap = false
                    local traps = udsvc:GetTrapsAtPos(pos)
                    if traps then
                        for index, e in ipairs(traps) do
                            if tarTrapId == e:Trap():GetTrapID() then
                                bPickTrap = true
                                break
                            end
                        end
                    end
                    if not bPickTrap then
                        if legendPower >= powerIfNoTrap then
                            firstPickPos = pos
                            table.insert(pickExtraParam, SkillTriggerTypeExtraParam.PickPosNoCfgTrap)
                            break
                        end
                    end
                else
                    firstPickPos = pos
                    break
                end
            end
        end
    end
    if firstPickPos then
        return { firstPickPos }, { firstPickPos }, {}, pickExtraParam
    else
        return {}, {}, {}, {}
    end
end