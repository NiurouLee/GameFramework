require("calc_base")

_class("SkillEffectCalc_ConductDamage", SkillEffectCalc_Base)
SkillEffectCalc_ConductDamage = SkillEffectCalc_ConductDamage

function SkillEffectCalc_ConductDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    local tResultArray = {}

    local teidTarget = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(teidTarget) do
        local results = self:CalculateOnSingleTarget(skillEffectCalcParam, targetID)
        table.appendArray(tResultArray, results)
    end

    return tResultArray
end

---@param calcParam SkillEffectCalcParam
function SkillEffectCalc_ConductDamage:CalculateOnSingleTarget(calcParam, targetID)
    ---@type SkillEffectParam_ConductDamage
    local effectParam = calcParam.skillEffectParam
    local attacker = self._world:GetEntityByID(calcParam.casterEntityID)

    local tConductResult = {}

    ---@type SkillContextComponent
    local cSkillContext = attacker:SkillContext()
    local resultContainer = cSkillContext:GetResultContainer()
    ---@type SkillDamageEffectResult[]
    local tDamageResultArray = resultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)
    for damageIndex, damageResult in ipairs(tDamageResultArray) do
        if damageResult:GetTargetID() == targetID then
            table.insert(tConductResult, self:CalculateResult(calcParam, attacker, damageIndex, damageResult))
        end
    end

    return tConductResult
end

---@param damageResult SkillDamageEffectResult
function SkillEffectCalc_ConductDamage:CalculateResult(calcParam, attacker, damageIndex, damageResult)
    local targetID = damageResult:GetTargetID()
    -- 计算传导的影响范围，拿目标，随机排序
    local scopeResult = self:CalcConductScope(calcParam, targetID)
    -- 分别为每位幸运目标计算伤害
    local targetSortedArray = scopeResult:GetGridPosTargetIDDic()
    local targetIDs = scopeResult:GetTargetIDs()

    ---@type SkillEffectParam_ConductDamage
    local effectParam = calcParam.skillEffectParam
    local tConductRate = effectParam:GetConductRateList()

    local conductResult = SkillEffectConductDamageResult:New(damageIndex, targetID)

    ---@type SkillContextComponent
    local cSkillContext = attacker:SkillContext()

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._world:GetService("SkillEffectCalc")

    local conductCount = 0
    for _, targetID in ipairs(targetIDs) do
        if conductCount > #(tConductRate) then
            break
        end

        conductCount = conductCount + 1
        local fConductRate = tConductRate[conductCount]

        if not fConductRate then
            break
        end

        local gridPos
        local defender = self._world:GetEntityByID(targetID)
        for i = 1, targetSortedArray:Size() do
            local entityID = targetSortedArray:GetAt(i)
            if entityID == targetID then
                gridPos = targetSortedArray:GetKeyAt(i)
                break
            end
        end

        local damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()

        cSkillContext:SetConductBaseDamage(damageResult:GetTotalDamage())
        cSkillContext:SetCurrentConductRate(fConductRate)

        local damageParam = SkillDamageEffectParam:New({
            percent = {fConductRate},
            formulaID = effectParam:GetFormulaID(),
            damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()
        })

        local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
            attacker,
            calcParam.attackPos,
            defender,
            gridPos,
            calcParam.skillID,
            damageParam,
            SkillEffectType.ConductDamage,
            effectParam:GetSkillEffectDamageStageIndex()
        )

        local damageEffectResult =
            effectCalcSvc:NewSkillDamageEffectResult(
            gridPos,
            targetID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
        )

        conductResult:CreateAtomData(
            conductCount, damageEffectResult
        )
    end

    return conductResult
end

---@return SkillScopeResult
function SkillEffectCalc_ConductDamage:CalcConductScope(calcParam, conductCenterEntityID)
    ---@type SkillEffectParam_ConductDamage
    local effectParam = calcParam.skillEffectParam
    local attacker = self._world:GetEntityByID(calcParam.casterEntityID)

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local calcScope = utilScopeSvc:GetSkillScopeCalc()

    -- 以受击点为范围中心
    local lastHitpoint = calcParam.gridPos
    local scopeType = effectParam:GetConductScopeType()
    local scopeParam = effectParam:GetConductScopeParam()
    local parser = SkillScopeParamParser:New()
    scopeParam = parser:ParseScopeParam(scopeType, scopeParam)
    local casterBodyArea = attacker:BodyArea():GetArea()
    local casterDirection = attacker:GetGridDirection()
    local targetType = effectParam:GetConductTargetType()

    local scopeResult = calcScope:ComputeScopeRange(
        scopeType,
        scopeParam,
        lastHitpoint,
        casterBodyArea,
        casterDirection,
        targetType,
        lastHitpoint
    )

    local selector = SkillScopeTargetSelector:New(self._world)
    local targetArray = selector:DoSelectSkillTarget(
        attacker, targetType, scopeResult
    )

    local rangeMap = {}

    local tv2AttackRange = scopeResult:GetAttackRange()
    for _, v2 in ipairs(tv2AttackRange) do
        local index = v2:Pos2Index()
        rangeMap[index] = true
    end

    for _, targetID in ipairs(targetArray) do
        if targetID ~= conductCenterEntityID then -- 不会对核心目标自身造成传导
            local entity = self._world:GetEntityByID(targetID)
            if entity and entity:HasBodyArea() then
                local v2GridPos = entity:GetGridPosition()
                ---@type BodyAreaComponent
                local cBodyArea = entity:BodyArea()
                local tv2BodyArea = cBodyArea:GetArea()
                for _, v2AreaPos in ipairs(tv2BodyArea) do
                    local v2AbsAreaPos = v2AreaPos + v2GridPos
                    local index = v2AbsAreaPos:Pos2Index()
                    if rangeMap[index] then
                        scopeResult:AddTargetIDAndPos(targetID, v2AbsAreaPos)
                        break -- 同一个目标不会被传导多次
                    end
                end
            end
        end
    end

    return scopeResult
end
