require("pick_up_policy_base")

_class("PickUpPolicy_NearestPos", PickUpPolicy_Base)
---@class PickUpPolicy_NearestPos: PickUpPolicy_Base
PickUpPolicy_NearestPos = PickUpPolicy_NearestPos

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_NearestPos:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    ---获取配置的点选的数量
    local pickUpNum = self:_GetPickUpNumByConfig(activeSkillID)

    local petColor = petEntity:Element():GetPrimaryType()
    local casterPos = petEntity:GridLocation().Position

    ---@type BoardServiceLogic
    local boardService = self._world:GetService("BoardLogic")
    
    ---需要返回的三个数据
    local posList = {}
    local targetIdList = {} --攻击目标
    local attackPosList = {} --攻击范围

    local ringMax = boardService:GetCurBoardRingMax()
    local casterPosIndex = self:_Pos2Index(casterPos)
    local env = self:_GetPickUpPolicyEnv()

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    for _, off in ipairs(ringMax) do
        local posIdx = self:_PosIndexAddOffset(casterPosIndex, off)
        if validPosIdxList[posIdx] then
            local pos = self:_Index2Pos(posIdx)
            --排除同色格子
            if env.BoardPosCanMove[posIdx] and env.BoardPosPieces[posIdx] ~= petColor then
                local result, targetIds = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pos)
                table.appendArray(attackPosList, result:GetAttackRange())
                table.appendArray(targetIdList, targetIds)
                posList[#posList + 1] = pos
                if #posList >= pickUpNum then
                    break
                end
            end
        end
    end
    return posList, attackPosList, targetIdList
end