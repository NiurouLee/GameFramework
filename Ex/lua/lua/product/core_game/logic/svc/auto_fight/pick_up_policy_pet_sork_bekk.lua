require("pick_up_policy_base")

_class("PickUpPolicy_PetSorkBekk", PickUpPolicy_Base)
---@class PickUpPolicy_PetSorkBekk: PickUpPolicy_Base
PickUpPolicy_PetSorkBekk = PickUpPolicy_PetSorkBekk

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetSorkBekk:CalcAutoFightPickUpPolicy(calcParam)
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
    
    local validResults = self:_CalcResults(petEntity, activeSkillID, validPosList, true)
    
    ---@type SkillConfigData
    local skillConfigData = configService:GetSkillConfigData(activeSkillID)

    local pickUpNum = tonumber(skillConfigData._pickUpParam[1])
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
function PickUpPolicy_PetSorkBekk:_CalcResults(petEntity, activeSkillID, validGirdList, needSetPickDir)
    local env = self:_GetPickUpPolicyEnv()
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()

    local results = {}
    local casterPos = petEntity:GetGridPosition()
    --随机点选位置
    table.shuffle(validGirdList)

    ---@type PreviewPickUpComponent
    local previewPickUpComponent = nil
    if needSetPickDir then
        if not petEntity:HasPreviewPickUpComponent() then
            petEntity:AddPreviewPickUpComponent()
        end
        previewPickUpComponent = petEntity:PreviewPickUpComponent()
    end
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local selectedDirection = {}
    for _, pos in ipairs(validGirdList) do
        local posIdx = self:_Pos2Index(pos)
        local direction = scopeCalculator:GetDirection(pos, casterPos)
        if table.icontains(selectedDirection, direction) then
            --方向不变不计算
        elseif env.BoardPosPieces[posIdx] then
            if previewPickUpComponent then
                previewPickUpComponent:AddDirection(direction, pos)
                previewPickUpComponent:AddGridPos(pos)
            end
            table.insert(selectedDirection, direction)
            
            local bombCenterPos = utilScopeSvc:AutoFightCalcBombPos(casterPos,pos)
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, bombCenterPos)
            --目标数量
            if #target_ids > 0 then
                table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
            end
            if previewPickUpComponent then
                previewPickUpComponent:ClearGridPos()
                previewPickUpComponent:ClearDirection()
            end
        end
    end

    return results
end
