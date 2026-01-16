require("pick_up_policy_base")

_class("PickUpPolicy_PetSPKaLianWithDamage", PickUpPolicy_Base)
---@class PickUpPolicy_PetSPKaLianWithDamage: PickUpPolicy_Base
PickUpPolicy_PetSPKaLianWithDamage = PickUpPolicy_PetSPKaLianWithDamage

---@param calcParam PickUpPolicy_CalcParam
function PickUpPolicy_PetSPKaLianWithDamage:CalcAutoFightPickUpPolicy(calcParam)
    local petEntity = calcParam.petEntity
    local activeSkillID = calcParam.activeSkillID
    local policyParam = calcParam.policyParam
    local casterPos = petEntity:GridLocation().Position

    local validPosIdxList,validPosList = self:_CalcPickUpValidGridList(petEntity,activeSkillID)
    local pickPosList, atkPosList, targetIds, extraParam =
        self:_CalPickPosPolicy_PetSPKaLian_WithDamage(calcParam.TT,petEntity, activeSkillID, casterPos, validPosList)
    return pickPosList, atkPosList, targetIds, extraParam
end
---@param petEntity Entity
---@param activeSkillID number
---@param casterPos Vector2
function PickUpPolicy_PetSPKaLianWithDamage:_CalPickPosPolicy_PetSPKaLian_WithDamage(TT, petEntity, activeSkillID, casterPos, validPosList)
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    local tInfo = {}
    for _, v2 in ipairs(validPosList) do
        local convertCount = 0
        --原先的转色范围与点选和逻辑结果有关，这里两者都没有，所以单独写一个
        local dir = utilScope:GetStandardDirection8D(v2 - casterPos)
        local posForward = v2 + dir
        local posBackward = v2 - dir
        if self:_PetKaLian_CanGridConvertToRed(posForward, casterPos) then
            convertCount = convertCount + 1
        end
        if self:_PetKaLian_CanGridConvertToRed(posBackward, casterPos) then
            convertCount = convertCount + 1
        end
        -- 如果这个位置无法生成新的火格子，则不释放技能，因此后续的逻辑都不用算了
        if convertCount > 0 then
            local tMonsters, tMonsterPos
            if self._world:MatchType() ~= MatchType.MT_BlackFist then
                tMonsters, tMonsterPos = utilScope:SelectNearestMonsterOnPos(v2, 1)
                YIELD(TT)
            else
                local enemyTeamEntity = petEntity:Pet():GetOwnerTeamEntity():Team():GetEnemyTeamEntity()
                tMonsters = {enemyTeamEntity}
                tMonsterPos = {enemyTeamEntity:GetGridPosition()}
            end

            ---@type SkillScopeCalculator
            local scopeCalculator = utilScope:GetSkillScopeCalc()
            local attackRangeScopeResult = scopeCalculator:ComputeScopeRange(
                    SkillScopeType.AngleFreeLine,
                    {widthThreshold=1,noExtend=1},
                    v2,
                    petEntity:BodyArea():GetArea(),
                    petEntity:GetGridDirection(),
                    SkillTargetType.MonsterTrap,
                    petEntity:GetGridPosition(),
                    petEntity
            )
            local attackRange = attackRangeScopeResult:GetAttackRange() or {}

            --选技能目标
            local targetSelector = self._world:GetSkillScopeTargetSelector()
            local targetIds = targetSelector:DoSelectSkillTarget(petEntity, SkillTargetType.Monster,attackRangeScopeResult,activeSkillID) or {}

            local candidateInfo = {
                index = #tInfo, --排序保底数据
                pos = v2,
                convertCount = convertCount,
                nearestMonsterCount = (#tMonsters),
                nearestMonsterDistance = (#tMonsterPos > 0) and Vector2.Distance(v2, tMonsterPos[1]) or nil,
                attackRange = attackRange,
                targetIds = targetIds
            }
            table.insert(tInfo, candidateInfo)
        end
    end

    if #tInfo == 0 then
        return {}, {}, {}, {}
    end

    table.sort(tInfo, function (a, b)
        --可转色格子较多者优先
        if a.convertCount ~= b.convertCount then
            return a.convertCount > b.convertCount
        end

        local countA = #(a.targetIds)
        local countB = #(b.targetIds)

        --转色格子数相同时，同时攻击到的怪物多者优先
        if countA ~= countB then
            return countA > countB
        end

        return a.index < b.index --纯保底
    end)

    local final = tInfo[1]
    YIELD(TT)

    return {final.pos}, final.attackRange, final.targetIds, {} --单纯的瞬移+转色
end
function PickUpPolicy_PetSPKaLianWithDamage:_PetKaLian_CanGridConvertToRed(pos, casterPos)
    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")
    ---@type BoardServiceLogic
    local lsvcBoard = self._world:GetService("BoardLogic")
    if not utilScope:IsValidPiecePos(pos) then
        return false
    end

    -- 需求如是，如果转色范围包含了施法者的当前坐标，认为“将当前位置转色为红色”
    if pos == casterPos then
        return true
    end

    if not lsvcBoard:GetCanConvertGridElement(pos) then
        return false
    end

    -- 已经是红色就不算是可以转为红色了
    if lsvcBoard:GetPieceType(pos) == PieceType.Red then
        return false
    end

    return true
end