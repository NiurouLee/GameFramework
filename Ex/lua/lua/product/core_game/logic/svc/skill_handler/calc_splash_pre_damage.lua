require("calc_base")

---@class SkillEffectCalc_SplashPreDamage : SkillEffectCalc_Base
_class("SkillEffectCalc_SplashPreDamage", SkillEffectCalc_Base)
SkillEffectCalc_SplashPreDamage = SkillEffectCalc_SplashPreDamage

function SkillEffectCalc_SplashPreDamage:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param param SkillEffectCalcParam
function SkillEffectCalc_SplashPreDamage:DoSkillEffectCalculator(param)
    ---@type Entity
    local attacker = self._world:GetEntityByID(param.casterEntityID)
    local cmptRoutine = attacker:SkillContext()

    ---@type SkillEffectParamSplashPreDamage
    local effectParam = param.skillEffectParam
    local splashCenterType = effectParam:GetSplashCenterType()

    -- if param.targetEntityIDs and #(param.targetEntityIDs) == 1 and param.targetEntityIDs[1] == -1 then
    --     -- 空放不计算
    --     return {SkillEffectSplashDamageResult:New(
    --         {},
    --         SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
    --         effectParam:GetSkillEffectDamageStageIndex()
    --     )}
    -- end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    ---@type SkillDamageEffectResult[]
    -- local tDamageResultArray = skillEffectResultContainer:GetEffectResultByArrayAll(SkillEffectType.Damage)
    -- local damagePosGroup = {}
    -- for damageIndex, damageResult in ipairs(tDamageResultArray) do
    --     if damageResult:GetDamageStageIndex() ==  then
    --         -- body
    --     end
    --     table.insert(damagePosGroup,damageResult:GetGridPos())
    -- end
    ---@type SkillDamageEffectResult[]
    local preDamageResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, effectParam:GetBaseDamageStageIndex())
    local curPos = param:GetGridPos()
    if not preDamageResults or (#preDamageResults==1 and  preDamageResults[1]:GetTargetID()==-1) then
        return {SkillEffectSplashDamageResult:New(
            {},
            SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
            effectParam:GetSkillEffectDamageStageIndex()
        )}
    end
    local splashDamageResults = {}
    ---@param result SkillDamageEffectResult[]
    for _, result in ipairs(preDamageResults) do
        -- 以受击点为中心计算范围
        local damageGridPos = result:GetGridPos()
        local damageIndex = result:GetDamageIndex()
        local lastHitpoint = damageGridPos
        if splashCenterType == SkillSplashCenterType.Caster then
            lastHitpoint = attacker:GetGridPosition()
        end
        ---@type UtilScopeCalcServiceShare
        local utilScopeSvc = self._world:GetService("UtilScopeCalc")
        ---@type SkillScopeCalculator
        local calcScope = utilScopeSvc:GetSkillScopeCalc()

        local scopeType = effectParam:GetSplashScopeType()
        local scopeParam = effectParam:GetSplashScopeParam()
        local parser = SkillScopeParamParser:New()
        scopeParam = parser:ParseScopeParam(scopeType, scopeParam)
        local casterBodyArea = attacker:BodyArea():GetArea()
        local casterDirection = attacker:GetGridDirection()
        local targetType = SkillTargetType.MonsterTrap -- TODO

        local splashScopeResult =
            calcScope:ComputeScopeRange(
            scopeType,
            scopeParam,
            lastHitpoint,
            casterBodyArea,
            casterDirection,
            SkillTargetType.MonsterTrap, -- TODO
            lastHitpoint
        )
        local baseDamage = result:GetTotalDamage()
        if baseDamage > 0 then
            ---@type SkillContextComponent
            local cSkillContext = attacker:SkillContext()
            cSkillContext:SetSplashBaseDamage(baseDamage)

            -- 用新范围获取挨打的目标
            local targetSelector = self._world:GetSkillScopeTargetSelector()
            local targetArray = targetSelector:DoSelectSkillTarget(attacker, SkillTargetType.MonsterTrap, splashScopeResult)
            local targetGridAreaMap = {}
            for _, targetEntityID in ipairs(targetArray) do
                local targetEntity = self._world:GetEntityByID(targetEntityID)
                if targetEntity then
                    targetGridAreaMap[targetEntityID] = {}

                    local targetCenterPos = targetEntity:GetGridPosition()
                    local bodyAreaComponent = targetEntity:BodyArea()
                    if bodyAreaComponent then
                        local bodyAreaArray = bodyAreaComponent:GetArea()
                        for _, areaPos in ipairs(bodyAreaArray) do
                            local absAreaPos = (areaPos + targetCenterPos)
                            if not targetGridAreaMap[absAreaPos.x] then
                                targetGridAreaMap[absAreaPos.x] = {}
                            end
                            targetGridAreaMap[absAreaPos.x][absAreaPos.y] = targetEntityID
                        end
                    else
                        if not targetGridAreaMap[targetCenterPos.x] then
                            targetGridAreaMap[targetCenterPos.x] = {}
                        end
                        targetGridAreaMap[targetCenterPos.x][targetCenterPos.y] = targetEntityID
                    end
                end
            end


            local attackRange = splashScopeResult:GetAttackRange()
            table.removev(attackRange, lastHitpoint)

            local resultArray = {}
            for _, attackPos in ipairs(attackRange) do
                if (targetGridAreaMap[attackPos.x]) and (targetGridAreaMap[attackPos.x][attackPos.y]) then
                    local defenderEntityID = (targetGridAreaMap[attackPos.x][attackPos.y])
                    ---@type Entity
                    local defender = self._world:GetEntityByID(defenderEntityID)
                    local attackerPos = param.attackPos
                    local gridPos = attackPos
                    ---@type SkillDamageEffectParam
                    local skillDamageParam = param.skillEffectParam

                    ---@type SkillEffectCalcService
                    local effectCalcSvc = self._skillEffectService
                    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
                    local nTotalDamage, listDamageInfo =
                        effectCalcSvc:ComputeSkillDamage(
                        attacker,
                        attackerPos,
                        defender,
                        gridPos,
                        param.skillID,
                        skillDamageParam,
                        SkillEffectType.SplashDamage,
                        damageStageIndex
                    )
                    ---@type SkillDamageEffectResult
                    local skillResult =
                        effectCalcSvc:NewSkillDamageEffectResult(
                        gridPos,
                        defenderEntityID,
                        nTotalDamage,
                        listDamageInfo,
                        damageStageIndex
                    )
                    skillResult:SetDamageIndex(damageIndex)
                    table.insert(resultArray, skillResult)

                end
            end

            table.insert(splashDamageResults,SkillEffectSplashDamageResult:New(resultArray, splashScopeResult, effectParam:GetSkillEffectDamageStageIndex()))
        end
    end
    if #splashDamageResults == 0 then
        return {SkillEffectSplashDamageResult:New(
            {},
            SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
            effectParam:GetSkillEffectDamageStageIndex()
        )}
    end
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
    for _, v in ipairs(splashDamageResults) do
        skillEffectResultContainer:AddEffectResult(v)
    end
    return splashDamageResults
end
