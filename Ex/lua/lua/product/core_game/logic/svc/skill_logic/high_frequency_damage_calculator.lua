_class("HighFrequencyDamageCalculator", Object)
---@class HighFrequencyDamageCalculator
HighFrequencyDamageCalculator = HighFrequencyDamageCalculator

---@param world MainWorld
function HighFrequencyDamageCalculator:Constructor(world)
    self._world = world
end

---@param casterEntity Entity
---@param effectParam SkillEffectParam_HighFrequencyDamage
function HighFrequencyDamageCalculator:Calculate(casterEntity, effectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type SkillScopeResult
    local scopeResult = skillEffectResultContainer:GetScopeResult()
    local targetIDs = scopeResult:GetTargetIDs()

    ---@type UtilScopeCalcServiceShare
    local utilScope = self._world:GetService("UtilScopeCalc")

    local v2CasterGridPos = casterEntity:GetGridPosition()
    local tTargetDistanceInfo = utilScope:GetEntityDistanceInfoArray(targetIDs, v2CasterGridPos)

    local effectCalcSvc = self._world:GetService("SkillEffectCalc")

    ---@type SkillDamageEffectResult[]
    local tDamageResults = {}

    ---@type MonsterShowLogicService
    local sMonsterShowLogic = self._world:GetService("MonsterShowLogic")

    local deadMonsterEntities = {}

    ---@type TriggerService
    local triggerSvc = self._world:GetService("Trigger")
    local finalAttackIndex = 0
    local damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()

    --根据周围指定范围内的指定颜色格子数量，增加伤害次数
    local attackTimes = effectParam:GetMaxAttackTimes()
    local extraAttackCount, addPiecePosList = self:_CalExtraAttackCount(effectParam, casterEntity)
    attackTimes = attackTimes + extraAttackCount

    for i = 1, attackTimes do
        if #tTargetDistanceInfo == 0 then
            break
        end

        local targetDistanceInfo = tTargetDistanceInfo[1]

        local eTarget = targetDistanceInfo.entity
        local nt = NTBeforeHighFrequencyDamageHit:New(casterEntity, i)
        triggerSvc:Notify(nt)

        local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
            casterEntity,
            v2CasterGridPos,
            eTarget,
            targetDistanceInfo.gridPos,
            skillID,
            effectParam,
            SkillEffectType.Damage,
            damageStageIndex
        )

        local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
            targetDistanceInfo.gridPos,
            targetDistanceInfo.targetID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
        )

        table.insert(tDamageResults, skillResult)

        local currentHP = eTarget:Attributes():GetCurrentHP()
        if currentHP <= 0 then
            table.remove(tTargetDistanceInfo, 1)
            
            sMonsterShowLogic:AddMonsterDeadMark(eTarget)
        end

        local ntAfter = NTAfterHighFrequencyDamageHit:New(casterEntity, i)
        triggerSvc:Notify(ntAfter)
    end

    local result = SkillEffectHighFrequencyDamageResult:New(tDamageResults)

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    skillEffectResultContainer:AddEffectResult(result)

    -- 牵引处理
    if #tDamageResults > 0 and effectParam:IsTractionOnLastTarget() then
        local lastDamageResult = tDamageResults[#tDamageResults]
        local targetID = lastDamageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetID)

        local tractionParam = SkillEffectMultiTractionParam:New(effectParam._paramList)

        ---@type SkillEffectCalc_MultiTraction
        local tractionCalc = SkillEffectCalc_MultiTraction:New(self._world)
        local tractionResult = tractionCalc:DoSkillEffectCalculator(SkillEffectCalcParam:New(
            casterEntity:GetID(),
            {targetID},
            tractionParam,
            skillID,
            scopeResult:GetAttackRange(),
            targetEntity:GetGridPosition(),
            targetEntity:GetGridPosition()
        ))

        skillEffectResultContainer:AddEffectResult(tractionResult)
        if tractionResult then
            local executor = SkillEffectLogicExecutor:New(self._world)
            executor:ApplySkillEffect(casterEntity, tractionParam, {tractionResult})
        end
    end

    -- 加buff处理
    if #tDamageResults > 0 and effectParam:GetLastTargetBuffID() then
        local lastDamageResult = tDamageResults[#tDamageResults]
        local targetID = lastDamageResult:GetTargetID()
        local targetEntity = self._world:GetEntityByID(targetID)

        local buffID = effectParam:GetLastTargetBuffID()
        local addBuffParam = SkillAddBuffEffectParam:New({
            prob = 1, buffID = buffID, 
        })
        ---@type SkillEffectCalc_AddBuff
        local addBuffCalc = SkillEffectCalc_AddBuff:New(self._world)
        local addBuffResult = addBuffCalc:DoSkillEffectCalculator(SkillEffectCalcParam:New(
            casterEntity:GetID(),
            {targetID},
            addBuffParam,
            skillID,
            scopeResult:GetAttackRange(),
            targetEntity:GetGridPosition(),
            targetEntity:GetGridPosition()
        ))

        if addBuffResult and (#addBuffResult > 0) then
            for _, r in ipairs(addBuffResult) do
                skillEffectResultContainer:AddEffectResult(r)
            end
            local executor = SkillEffectLogicExecutor:New(self._world)
            executor:ApplySkillEffect(casterEntity, addBuffParam, addBuffResult)
        end
    end

    local btsvc = self._world:GetService("Battle")
    if btsvc:IsFinalAttack() then
        result:SetFinalAttackIndex(#tDamageResults)
    end

    return result
end

--计算额外攻击次数
---@param param SkillEffectParam_HighFrequencyDamage
function HighFrequencyDamageCalculator:_CalExtraAttackCount(param, attacker)
    --计算指定区域的格子数量
    local serialScopeType = param:GetSerialScopeType()
    if not serialScopeType then
        return 0, {}
    end

    local radius = param:GetRadius()
    local posCaster = attacker:GetGridPosition()
    local casterBodyArea = attacker:BodyArea():GetArea()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalculator = utilScopeSvc:GetSkillScopeCalc()
    local scopeResult =
        scopeCalculator:ComputeScopeRange(serialScopeType, {[1] = radius, [2] = 0}, posCaster, casterBodyArea)
    ---@type BoardComponent
    local board = self._world:GetBoardEntity():Board()

    --计算额外攻击次数
    local extraAttackCount = 0
    local boardService = self._world:GetService("BoardRender")
    local pieceType = param:GetPieceType()
    ---@type Vector2[]
    local addPiecePosList = {}
    if scopeResult then
        local array = scopeResult:GetAttackRange()
        for _, v in ipairs(array) do
            local pt = board:GetPieceType(v)
            if pt == pieceType then
                extraAttackCount = extraAttackCount + 1
                table.insert(addPiecePosList, v)
            end
        end
    end
    local onPieceAddAttackCount = param:GetOnePieceAddAttackCount()
    extraAttackCount = extraAttackCount * onPieceAddAttackCount
    return extraAttackCount, addPiecePosList
end
