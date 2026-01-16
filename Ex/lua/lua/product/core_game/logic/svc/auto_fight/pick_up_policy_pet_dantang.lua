require("pick_up_policy_base")

_class("PickUpPolicy_PetDanTang", PickUpPolicy_Base)
---@class PickUpPolicy_PetDanTang: PickUpPolicy_Base
PickUpPolicy_PetDanTang = PickUpPolicy_PetDanTang

--计算技能范围和目标
---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetDanTang:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    --结果
    local pickPosList = {} --点选格子
    local attackPosList = {} --攻击范围
    local targetIdList = {} --攻击目标

    local validPosIdxList, validPosList = self:_CalcPickUpValidGridList(petEntity, activeSkillID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    local monsterList, monsterPosList = utilScopeSvc:SelectAllMonster()
    for i, pos in ipairs(monsterPosList) do
        table.removev(validPosList, pos)
    end

    --与default不同的是这里
    local t = {}
    for _, pos in ipairs(validPosList) do
        local posIdx = self:_Pos2Index(pos)
        local env = self:_GetPickUpPolicyEnv()
        local color = env.BoardPosPieces[posIdx]
        if color and color ~= PieceType.Red then
            t[#t + 1] = pos
        end
    end
    validPosList = t

    if table.count(validPosList) <= 2 then
        for _, pos in ipairs(validPosList) do
            table.insert(pickPosList, pos)
        end
        return pickPosList, attackPosList, targetIdList
    end

    local firstPickUpPos = nil

    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScope:GetSkillScopeCalc()

    --自己周围一圈内的非火格子，随机
    for i = 1, 9 do
        local curPos = petEntity:GetGridPosition()
        local curBodyArea = petEntity:BodyArea():GetArea()
        local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.SquareRing, {1}, curPos, curBodyArea)

        for _, pos in ipairs(scopeResult:GetAttackRange()) do
            if table.icontains(validPosList, pos) then
                firstPickUpPos = pos
                break
            end
        end

        if firstPickUpPos then
            break
        end
    end
    if not firstPickUpPos then
        firstPickUpPos = validPosList[1]
    end

    local hasCalcPosList = {}
    table.insert(hasCalcPosList, firstPickUpPos)

    local results = {}

    for i, e in ipairs(monsterList) do
        local curPos = e:GetGridPosition()
        local curBodyArea = e:BodyArea():GetArea()
        local scopeResult = scopeCalculator:ComputeScopeRange(SkillScopeType.SquareRing, {1}, curPos, curBodyArea)

        for _, pos in ipairs(scopeResult:GetAttackRange()) do
            if table.icontains(validPosList, pos) and not table.icontains(hasCalcPosList, pos) then
                local scope_result, target_ids =
                    self:_CalcSkillScopeResultAndTargets_PickUpPolicy(petEntity, activeSkillID, {firstPickUpPos, pos})
                --目标数量
                if #target_ids > 0 then
                    table.insert(results, {pos, target_ids, scope_result:GetAttackRange()})
                end

                table.insert(hasCalcPosList, pos)
            end
        end
    end

    --伤害目标最多
    if #results > 0 then
        table.sort(
            results,
            function(a, b)
                return #a[2] > #b[2]
            end
        )

        pickPosList = {firstPickUpPos, results[1][1]}
        table.appendArray(targetIdList, results[1][2])
        table.appendArray(attackPosList, results[1][3])
    end
    return pickPosList, attackPosList, targetIdList
end
