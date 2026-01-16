--[[------------------------------------------------------------------------------------------
    ForEachTargetCalculator :对单个目标计算一个技能子效果
]] --------------------------------------------------------------------------------------------

---@class ForEachTargetCalculator: Object
_class("ForEachTargetCalculator", Object)
ForEachTargetCalculator = ForEachTargetCalculator

---@param world MainWorld
function ForEachTargetCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type ConfigService
    self._configService = self._world:GetService("Config")

    ---@type SkillEffectCalcService
    self._skillEffectCalcService = self._world:GetService("SkillEffectCalc")

    self._canEffectSelectTargetByGrid = {
        [SkillEffectType.Damage] = true,
        [SkillEffectType.SplashDamage] = true,
        [SkillEffectType.DamageOnTargetCount] = true,
        [SkillEffectType.DamageByBuffLayer] = true
    }
end

---@param casterEntity Entity 施法者
---@param scopeResult SkillScopeResult 范围
---@param targetIDArray Array 目标列表
---@param skillEffectParam SkillEffectParamBase 子效果配置参数
---@param scopeFilterParam SkillScopeFilterParam 范围过滤参数
function ForEachTargetCalculator:DoTargetEffectCalculate(
    casterEntity,
    scopeResult,
    targetIDArray,
    skillEffectParam,
    scopeFilterParam)
    ---统计本效果产生的所有结果
    local effectResultList = {}
    if targetIDArray == nil or #targetIDArray == 0 then
        ---假如没有目标，也需要算一个result，这样表现才能用
        local skillResult = self:_CalcNoTarget(casterEntity, scopeResult, skillEffectParam)
        if skillResult ~= nil then
            if skillResult._className ~= nil then
                effectResultList[#effectResultList + 1] = skillResult
            else
                for _, v in ipairs(skillResult) do
                    effectResultList[#effectResultList + 1] = v
                end
            end
        end
    else
        ---遍历所有要作用的目标
        for _, targetEntityID in ipairs(targetIDArray) do
            local skillResult =
                self:_CalcEachTarget(
                casterEntity,
                targetEntityID,
                scopeResult,
                skillEffectParam,
                scopeFilterParam,
                targetIDArray
            )
            if skillResult ~= nil then
                if skillResult._className ~= nil then
                    effectResultList[#effectResultList + 1] = skillResult
                else
                    for _, v in ipairs(skillResult) do
                        effectResultList[#effectResultList + 1] = v
                    end
                end
            end
        end
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    for _, v in ipairs(effectResultList) do
        skillEffectResultContainer:AddEffectResult(v)
    end

    return effectResultList
end

---没有目标，只是通过技能计算出一个result，然后表现可以空放
---@param scopeResult SkillScopeResult
function ForEachTargetCalculator:_CalcNoTarget(casterEntity, scopeResult, skillEffectParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("caster has no skill routine component")
    end
    local calcParam =
        SkillEffectCalcParam:New(
        casterEntity:GetID(),
        {-1}, -- 原先这里是nil
        skillEffectParam,
        skillEffectResultContainer:GetSkillID(),
        scopeResult:GetAttackRange(),
        nil,
        casterEntity:GetGridPosition(),
        scopeResult:GetCenterPos(),
        scopeResult:GetWholeGridRange()
    )
    ---这里返回的是一个数组
    local skillResult = self._skillEffectCalcService:CalcSkillEffectByType(calcParam)
    return skillResult
end

---单个目标身上所有技能效果的计算
---@param casterEntity Entity
---@param scopeResult SkillScopeResult 范围
---@param skillEffectParam SkillEffectParamBase
function ForEachTargetCalculator:_CalcEachTarget(
    casterEntity,
    targetEntityID,
    scopeResult,
    skillEffectParam,
    scopeFilterParam,
    targetIDArray)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    if skillEffectResultContainer == nil then
        Log.fatal("caster has no skill routine component")
    end

    local skillID = skillEffectResultContainer:GetSkillID()

    ---@type Entity
    local targetEntity = self._world:GetEntityByID(targetEntityID)
    if targetEntity == nil then
        Log.fatal("targetEntity is nil")
        return
    end

    local targetGridPos = nil
    if targetEntity:GridLocation() then
        targetGridPos = targetEntity:GridLocation().Position
    end

    local skillRange = scopeResult:GetAttackRange()
    local wholeRange = scopeResult:GetWholeGridRange()
    local scopeCenter = scopeResult:GetCenterPos()
    local specialScopeResult = scopeResult:GetSpecialScopeResult()

    ---@type SkillEffectType
    local effectType = skillEffectParam:GetEffectType()

    if effectType == SkillEffectType.SerialKiller then
        return
    end

    local targetSelectionMode = scopeFilterParam:GetTargetSelectionMode()

    local resultArray

    -- ！注意：如果targetEntity没有BodyArea，则改为根据实体获取目标！
    ---@type BodyAreaComponent|nil
    local bodyAreaComponent = targetEntity:BodyArea()
    local canSelectByGrid = self._canEffectSelectTargetByGrid[skillEffectParam:GetEffectType()]
    if
        ((canSelectByGrid) and -- 技能效果支持
            ((not targetSelectionMode) or targetSelectionMode == SkillTargetSelectionMode.Grid) and -- 配置为按格选取
            bodyAreaComponent)
     then -- 目标可以计算占据格子
        local bodyAreaArray = bodyAreaComponent:GetArea()
        local targetBodyAreaPosList = {}
        for _, areaPos in ipairs(bodyAreaArray) do
            local gridPos = areaPos + targetGridPos
            table.insert(targetBodyAreaPosList, gridPos)
        end

        --默认是根据target的身形顺序计算
        local calcRange = {}
        for _, gridPos in ipairs(targetBodyAreaPosList) do
            if self:IsInSkillRange(skillRange, gridPos) then
                table.insert(calcRange, gridPos)
            end
        end

        --配置-根据范围计算的顺序计算
        if skillEffectParam.GetUseScopeOrder and skillEffectParam:GetUseScopeOrder() == 1 then
            calcRange = {}
            for _, gridPos in ipairs(skillRange) do
                if table.intable(targetBodyAreaPosList, gridPos) then
                    table.insert(calcRange, gridPos)
                end
            end
        end

        for _, gridPos in ipairs(calcRange) do
            local calcParam =
                SkillEffectCalcParam:New(
                casterEntity:GetID(),
                {targetEntityID},
                skillEffectParam,
                skillID,
                skillRange,
                casterEntity:GridLocation():GetGridPos(),
                gridPos,
                scopeCenter,
                wholeRange
            )
            calcParam:SetTotalTargetCount(#targetIDArray)
            if specialScopeResult then
                calcParam:SetSpecialScopeResult(specialScopeResult)
            end
            --“格子伤害”的数据，区别于单位伤害
            calcParam:SetDamageGridPos(gridPos)

            local skillResult = self._skillEffectCalcService:CalcSkillEffectByType(calcParam)
            if (not resultArray) and (skillResult) then
                resultArray = {}
            end
            table.appendArray(resultArray, skillResult)
        end
    else
        local calcParam =
            SkillEffectCalcParam:New(
            casterEntity:GetID(),
            {targetEntityID},
            skillEffectParam,
            skillID,
            skillRange,
            casterEntity:GridLocation():GetGridPos(),
            targetGridPos,
            scopeCenter,
            wholeRange
        )
        calcParam:SetTotalTargetCount(#targetIDArray)
        if specialScopeResult then
            calcParam:SetSpecialScopeResult(specialScopeResult)
        end

        local skillResult = self._skillEffectCalcService:CalcSkillEffectByType(calcParam)

        if skillResult then
            if (not resultArray) then
                resultArray = {}
            end

            if skillResult._className then
                table.insert(resultArray, skillResult)
            else
                table.appendArray(resultArray, skillResult)
            end
        end
    end

    return resultArray
end

function ForEachTargetCalculator:IsInSkillRange(skillRange, gridPos)
    for _, v in ipairs(skillRange) do
        if #v ~= 0 then
            for k, pos in ipairs(v) do
                if pos.x == gridPos.x and pos.y == gridPos.y then
                    return true
                end
            end
        else
            if v.x == gridPos.x and v.y == gridPos.y then
                return true
            end
        end
    end
    return false
end
