require("pick_up_policy_base")

_class("PickUpPolicy_PetYeliyaExtra", PickUpPolicy_Base)
---@class PickUpPolicy_PetYeliyaExtra: PickUpPolicy_Base
PickUpPolicy_PetYeliyaExtra = PickUpPolicy_PetYeliyaExtra

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetYeliyaExtra:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetYeliyaExtra(petEntity, activeSkillID, casterPos,validPosIdxList)
    return pickPosList, atkPosList, targetIds, extraParam
end
function PickUpPolicy_PetYeliyaExtra:_CalPickPosPolicy_PetYeliyaExtra(petEntity, activeSkillID, casterPos, validPosIdxList)
    ---@type ConfigService
    local configService = self._world:GetService("Config")
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)
    local checkDamageSkillID = 30018411
    local policyParam = skillConfigData:GetAutoFightPickPosPolicyParam()
    if policyParam then
        if policyParam.checkDamageSkillID then
            checkDamageSkillID = tonumber(policyParam.checkDamageSkillID)
        end
    end

    local pickPosList = {}
    local retScopeResult = {}
    local retTargetIds = {}

    local testPickPos = nil
    local tmpPickList = {}
    testPickPos = self:_YeliyaFindValidPosWithMaxTargetCount(petEntity,casterPos,validPosIdxList,tmpPickList,checkDamageSkillID)
    if testPickPos then
        table.insert(pickPosList, testPickPos)
        --retScopeResult, retTargetIds = self:_CalcSkillScopeResultAndTargets(petEntity, activeSkillID, pickPosList)
    else
        return {},{},{}
    end
    return pickPosList, retScopeResult, retTargetIds
end
function PickUpPolicy_PetYeliyaExtra:_YeliyaFindValidPosWithMaxTargetCount(petEntity,centerPos,validPosIdxList,alreadyPickList,checkDamageSkillID)
    local pickPos = nil

    checkDamageSkillID = 30018411
    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    local ringMax = boardService:GetCurBoardRingMax()
    local centerPosIndex = self:_Pos2Index(centerPos)
    local maxTargetCount = 0
    local maxTargetPos = nil
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(centerPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            if not table.icontains(alreadyPickList,pos) then
                local isBlockedLinkLine = boardService:IsPosBlock(pos, BlockFlag.LinkLine)
                if not isBlockedLinkLine then
                    local result, targetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, checkDamageSkillID, pos)
                    if targetIds then
                        local targetCount = #targetIds
                        if targetCount > maxTargetCount then
                            maxTargetCount = targetCount
                            maxTargetPos = pos
                        end
                    end
                end
            end
        end
    end
    if maxTargetPos then
        pickPos = maxTargetPos
    end
    return pickPos
end