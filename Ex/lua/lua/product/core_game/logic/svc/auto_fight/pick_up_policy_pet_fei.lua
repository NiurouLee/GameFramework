require("pick_up_policy_base")

_class("PickUpPolicy_PetFei", PickUpPolicy_Base)
---@class PickUpPolicy_PetFei: PickUpPolicy_Base
PickUpPolicy_PetFei = PickUpPolicy_PetFei

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetFei:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    ---@type ConfigService
    local configService = self._world:GetService("Config")
    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    --与default不同的是这里
    local t = {}
    for _, pos in ipairs(validPosList) do
        local posIdx = self:_Pos2Index(pos)
        local env = self:_GetPickUpPolicyEnv()
        local color = env.BoardPosPieces[posIdx]
        if color and color ~= PieceType.Green then
            t[#t + 1] = pos
        end
    end
    validPosList = t
    
    local validResults = self:_CalcValidResultByPickUpType_PickUpPolicy(petEntity, activeSkillID, validPosList)
    
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)

    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
    local pickUpType = skillConfigData:GetSkillPickType()

    --伤害目标最多
    if #validResults > 0 then
        table.sort(
                validResults,
                function(a, b)
                    return #a[2] > #b[2]
                end
        )
        for i = 1, pickUpNum do
            local t = validResults[i]
            if not t then
                break
            end
            pickPosList[i] = t[1]
            table.appendArray(targetIdList, t[2])
            table.appendArray(attackPosList, t[3])
        end
        return pickPosList, attackPosList, targetIdList
    end
    return pickPosList, attackPosList, targetIdList
end