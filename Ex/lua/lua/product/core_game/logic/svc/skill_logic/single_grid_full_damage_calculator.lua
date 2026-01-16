--SingleGridFullDamageCalculator
_class("SingleGridFullDamageCalculator", Object)
---@class SingleGridFullDamageCalculator : Object
SingleGridFullDamageCalculator = SingleGridFullDamageCalculator

---
---@param world MainWorld
function SingleGridFullDamageCalculator:Constructor(world)
    self._world = world
end

---
---@param casterEntity Entity
---@param effectParam SkillEffectParam_SingleGridFullDamage
---@param finalScopeFilterParam SkillScopeFilterParam
---@return table
function SingleGridFullDamageCalculator:Calculate(casterEntity, effectParam, finalScopeFilterParam, skillID)
    ---@type GeneralEffectCalculator
    local generalCalc = GeneralEffectCalculator:New(self._world)
    ---@type SkillScopeResult
    local skillScopeResult = generalCalc:_CalcSkillEffectScopeResult(casterEntity, effectParam, finalScopeFilterParam)
    local targetIDList = generalCalc:_CalcSkillEffectTargetList(casterEntity, skillScopeResult, effectParam)

    local tAttackRange = skillScopeResult:GetAttackRange()
    ---@type SkillDamageEffectResult[]
    local tResult = {}
    local targetIDChecker = {}
    for _, eid in ipairs(targetIDList) do
        ---@type Entity
        local defender = self._world:GetEntityByID(eid)
        if not defender then
            goto SKIP_INVALID_TARGET
        end

        local v2LogicPos = defender:GetGridPosition()
        local tBodyArea = defender:BodyArea():GetArea()
        for _, v2Relative in ipairs(tBodyArea) do
            local v2 = v2Relative + v2LogicPos
            if not table.icontains(tAttackRange, v2) then
                goto SKIP_OUT_OF_RANGE
            end

            self:_CalculateDamageOnce(
                    casterEntity, defender, effectParam, v2, skillID, targetIDChecker[eid], tResult
            )

            targetIDChecker[eid] = true
            ::SKIP_OUT_OF_RANGE::
        end

        ::SKIP_INVALID_TARGET::
    end

    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    for _, result in ipairs(tResult) do
        result:SetSkillEffectScopeResult(skillScopeResult)
        skillEffectResultContainer:AddEffectResult(result)
    end

    return tResult
end

---@param casterEntity Entity
---@param defenderEntity Entity
---@param effectParam SkillEffectParam_SingleGridFullDamage
function SingleGridFullDamageCalculator:_CalculateDamageOnce(
        casterEntity, defenderEntity, effectParam, v2GridPos, skillID, isDamageReduced, tResult
)
    local damageIncreaseBuffEffectType = effectParam:GetDamageIncreaseBuffEffectType()
    local damageIncreaseMul = effectParam:GetDamageIncreaseMul()

    if damageIncreaseBuffEffectType and damageIncreaseMul then
        ---@type SkillContextComponent
        local cSkillContext = casterEntity:SkillContext()
        cSkillContext:SetDamagePctIncreaseBuffEffectType(damageIncreaseBuffEffectType)
        cSkillContext:SetDamagePctIncreaseMul(damageIncreaseMul)
    end

    local damageParam = SkillDamageEffectParam:New({})
    for k, v in pairs(effectParam) do
        damageParam[k] = v
    end
    if isDamageReduced then
        local percent = {}
        for k, v in pairs(effectParam:GetDamagePercent()) do
            percent[k] = v * effectParam:GetMultiGridDecreaseRate()
        end
        damageParam._percent = percent
    end

    ---@type SkillEffectCalcService
    local lsvcSkillEffectCalc = self._world:GetService("SkillEffectCalc")

    local damageStageIndex = effectParam:GetSkillEffectDamageStageIndex()
    local nTotalDamage, listDamageInfo = lsvcSkillEffectCalc:ComputeSkillDamage(
        casterEntity,
        casterEntity:GetGridPosition(),
        defenderEntity,
        v2GridPos,
        skillID,
        damageParam,
        SkillEffectType.Damage,
        damageStageIndex
    )

    table.insert(tResult, lsvcSkillEffectCalc:NewSkillDamageEffectResult(
        v2GridPos,
        defenderEntity:GetID(),
        nTotalDamage,
        listDamageInfo,
        damageStageIndex
    ))
end
