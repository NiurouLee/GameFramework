require("pick_up_policy_base")

_class("PickUpPolicy_Default", PickUpPolicy_Base)
---@class PickUpPolicy_Default: PickUpPolicy_Base
PickUpPolicy_Default = PickUpPolicy_Default

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_Default:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    ---@type ConfigService
    local configService = self._world:GetService("Config")

    ---@type AutoFightService
    local autoFightSvc = self._world:GetService("AutoFight")

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    
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
        if pickUpType == SkillPickUpType.PickAndDirectionInstruction or
                pickUpType == SkillPickUpType.PickAndTeleportInst or
                pickUpType == SkillPickUpType.LineAndDirectionInstruction
        then
            local t = validResults[1]
            pickPosList = { t[1], t[4] }
            targetIdList = t[2]
            attackPosList = t[3]
        elseif pickUpType == SkillPickUpType.PickOnePosAndRotate then
            local t = validResults[1]
            for i = 1, t[4] do
                pickPosList[#pickPosList + 1] = t[1]
            end
            targetIdList = t[2]
            attackPosList = t[3]
        elseif pickUpType == SkillPickUpType.PickSwitchInstruction then
            local t = validResults[1]
            pickPosList = { t[1] }
            targetIdList = t[2]
            attackPosList = t[3]
        elseif pickUpType == SkillPickUpType.PickDiffPowerInstruction then
            local t = validResults[1]
            pickPosList = { t[1] }
            targetIdList = t[2]
            attackPosList = t[3]
        else
            for i = 1, pickUpNum do
                local t = validResults[i]
                if not t then
                    break
                end
                pickPosList[i] = t[1]
                table.appendArray(targetIdList, t[2])
                table.appendArray(attackPosList, t[3])
            end
        end

        return pickPosList, attackPosList, targetIdList
    end
    return pickPosList, attackPosList, targetIdList
end