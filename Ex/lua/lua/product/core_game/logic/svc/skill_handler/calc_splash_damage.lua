require("calc_base")

---@class SkillEffectCalc_SplashDamage : SkillEffectCalc_Base
_class("SkillEffectCalc_SplashDamage", SkillEffectCalc_Base)
SkillEffectCalc_SplashDamage = SkillEffectCalc_SplashDamage

function SkillEffectCalc_SplashDamage:Constructor(world)
    ---@type MainWorld
    self._world = world
    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param param SkillEffectCalcParam
function SkillEffectCalc_SplashDamage:DoSkillEffectCalculator(param)
    local attacker = self._world:GetEntityByID(param.casterEntityID)
    local cmptRoutine = attacker:SkillContext()

    ---@type SkillEffectParamSplashDamage
    local effectParam = param.skillEffectParam

    if param.targetEntityIDs and #(param.targetEntityIDs) == 1 and param.targetEntityIDs[1] == -1 then
        -- 空放不计算
        return {SkillEffectSplashDamageResult:New(
            {},
            SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
            effectParam:GetSkillEffectDamageStageIndex()
        )}
    end

    -- 以scopeResult的受击点为中心计算范围
    local lastHitpoint = param.gridPos
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

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()

    ---@type SkillDamageEffectResult[]
    local damageResults = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, effectParam:GetBaseDamageStageIndex())
    if not damageResults then
        return {SkillEffectSplashDamageResult:New(
            {},
            SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
            effectParam:GetSkillEffectDamageStageIndex()
        )}
    end
    local baseDamage = 0
    for _, result in ipairs(damageResults) do
        if result:GetGridPos() == param.gridPos then
            baseDamage = result:GetTotalDamage()
        end
    end
    if baseDamage <= 0 then
        return {SkillEffectSplashDamageResult:New(
            {},
            SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {}),
            effectParam:GetSkillEffectDamageStageIndex()
        )}
    end

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

    local resultArray = {}

    local attackRange = splashScopeResult:GetAttackRange()
    table.removev(attackRange, lastHitpoint)

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

            local skillResult =
                effectCalcSvc:NewSkillDamageEffectResult(
                gridPos,
                defenderEntityID,
                nTotalDamage,
                listDamageInfo,
                damageStageIndex
            )
            table.insert(resultArray, skillResult)
        end
    end

    return {SkillEffectSplashDamageResult:New(resultArray, splashScopeResult, effectParam:GetSkillEffectDamageStageIndex())}
end
