require("pick_up_policy_base")

_class("PickUpPolicy_PetJudge", PickUpPolicy_Base)
---@class PickUpPolicy_PetJudge: PickUpPolicy_Base
PickUpPolicy_PetJudge = PickUpPolicy_PetJudge

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetJudge:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicyPetJudge(petEntity, activeSkillID, validPosList, validPosIdxList)
    return pickPosList, atkPosList, targetIds, extraParam
end
--法官：地图上没有石膏机关，则在周围两圈随机释放；如果有，则选择能摧毁最多石膏机关的位置
function PickUpPolicy_PetJudge:_CalPickPosPolicyPetJudge(petEntity, activeSkillID, validPosList, validPosIdxList)
    local env = self:_GetPickUpPolicyEnv()
    local petEntityID = petEntity:GetID()
    local petTraps = {}
    local trapGroup = self._world:GetGroup(self._world.BW_WEMatchers.Trap)
    for _, e in ipairs(trapGroup:GetEntities()) do
        if not e:HasDeadMark() and e:HasSummoner() then
            ---@type Entity
            local summonEntity = e:GetSummonerEntity()
            if summonEntity and summonEntity:HasSuperEntity() then
                summonEntity = summonEntity:GetSuperEntity()
            end
            if summonEntity then
                local summonEntityID = summonEntity:GetID()
                if petEntityID == summonEntityID then
                    table.insert(petTraps,e)
                end
            end
        end
    end
    local pickPos = nil
    local pickScopeRange = nil
    if #petTraps == 0 then
        --自身周围两圈随机释放
        local ringNum = 2
        local posList = self:GetPosListAroundBodyArea(petEntity, ringNum)
        --随机点选位置
        table.shuffle(posList)
        for _, pos in ipairs(posList) do
            local posIdx = self:_Pos2Index(pos)
            if validPosIdxList[posIdx] then
                pickPos = pos
                break
            end
        end
        if pickPos then
            local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pickPos)
            pickScopeRange = scope_result:GetAttackRange()
        end
    else
        --能摧毁最多机关的位置
        --随机点选位置
        table.shuffle(validPosList)
        local results = {}
        for _, pos in ipairs(validPosList) do
            local posIdx = self:_Pos2Index(pos)
            if env.BoardPosPieces[posIdx] then
                local scope_result, target_ids = self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, pos)
                --目标数量
                if #target_ids > 0 then
                    table.insert(results, { pos, target_ids, scope_result:GetAttackRange() })
                end
            end
        end
        
        if #results > 0 then
            table.sort(
                results,
                function(a, b)
                    return #a[2] > #b[2]
                end
            )
            local tarResult = results[1]
            pickPos = tarResult[1]
            pickScopeRange = tarResult[3]
        end
    end
    if pickPos then
        return {pickPos},pickScopeRange,{petEntityID}
    else
        return {},{},{}
    end
end