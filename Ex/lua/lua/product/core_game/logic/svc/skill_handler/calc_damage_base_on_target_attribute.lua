--[[
    DamageBasedOnTargetAttribute = 90, --根据技能目标属性判断是否造成伤害(目标血量低于30%追加伤害,弥加德)
]]
require("calc_base")

---@class SkillEffectCalc_DamageBasedOnTargetAttribute: SkillEffectCalc_Base
_class("SkillEffectCalc_DamageBasedOnTargetAttribute", SkillEffectCalc_Base)
SkillEffectCalc_DamageBasedOnTargetAttribute = SkillEffectCalc_DamageBasedOnTargetAttribute

function SkillEffectCalc_DamageBasedOnTargetAttribute:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageBasedOnTargetAttribute:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}

    local targets = skillEffectCalcParam:GetTargetEntityIDs()
    for _, targetID in ipairs(targets) do
        local result = self:_CalculateSingleTarget(skillEffectCalcParam, targetID)
        if result then
            table.appendArray(results, result)
        end
    end

    return results
end

function SkillEffectCalc_DamageBasedOnTargetAttribute:_OnGetCompareAttribute(
    attacker,
    defender,
    entityTag,
    attribute,
    param)
    local entity
    if entityTag == "SkillTarget" then
        entity = defender
    elseif entityTag == "Self" then
        entity = attacker
    else
        Log.notice("_OnGetCompareAttribute entity is null.  entityTag =", entityTag)
    end
    if attribute == "MaxHP" then
        local maxHP = entity:Attributes():CalcMaxHp()
        maxHP = math.floor(maxHP * param)
        return maxHP
    end
    local entityAttribute = entity:Attributes():GetAttribute(attribute)
    entityAttribute = math.floor(entityAttribute * param)

    return entityAttribute
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageBasedOnTargetAttribute:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillDamageBasedOnTargetAttributeEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    -------在做表现的时候 考虑这个效果是否需要空结果，

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end
    --------

    -------------- 判断阶段
    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    local targetTag = skillDamageParam:GetTarget()
    local argetAttribute = skillDamageParam:GetTargetAttribute()
    local compareTag = skillDamageParam:GetCompare()
    local compareAttribute = skillDamageParam:GetCompareAttribute()
    local compareParam = skillDamageParam:GetCompareParam()

    local targetAttribute = self:_OnGetCompareAttribute(attacker, defender, targetTag, argetAttribute, 1)
    local compareAttribute = self:_OnGetCompareAttribute(attacker, defender, compareTag, compareAttribute, compareParam)

    local compareSymbol = skillDamageParam:GetCompareSymbol()
    local satisfied = false
    if compareSymbol == ComparisonOperator.EQ then --eq
        satisfied = targetAttribute == compareAttribute
    elseif compareSymbol == ComparisonOperator.NE then --ne
        satisfied = targetAttribute ~= compareAttribute
    elseif compareSymbol == ComparisonOperator.GT then --gt
        satisfied = targetAttribute > compareAttribute
    elseif compareSymbol == ComparisonOperator.GE then --ge
        satisfied = targetAttribute >= compareAttribute
    elseif compareSymbol == ComparisonOperator.LT then --lt
        satisfied = targetAttribute < compareAttribute
    elseif compareSymbol == ComparisonOperator.LE then --le
        satisfied = targetAttribute <= compareAttribute
    end

    if not satisfied then
        return
    end

    --检测施法者是否拥有指定buff
    local ownerBuffEffect = skillDamageParam:GetOwnerBuffEffect()
    if ownerBuffEffect then
        if not attacker:BuffComponent():HasBuffEffect(ownerBuffEffect) then
            return
        end
    end

    --检查是否需要前置伤害阶段，被攻击目标需要在前置伤害阶段内有结果
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
    local preDamageStageIndex = skillDamageParam:GetPreDamageStageIndex()
    if preDamageStageIndex then
        ---@type SkillEffectResultContainer
        local skillEffectResultContainer = attacker:SkillContext():GetResultContainer()
        local damageResultArray =
            skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Damage, preDamageStageIndex)

        if not damageResultArray or table.count(damageResultArray) == 0 then
            return
        end

        local defenderDamageResult
        for _, v in ipairs(damageResultArray) do
            ---@type SkillDamageEffectResult
            local damageResult = v
            local targetEntityID = damageResult:GetTargetID()
            if targetEntityID == defenderEntityID then
                defenderDamageResult = damageResult
                break
            end
        end

        if not defenderDamageResult then
            return
        end
    end

    --------------

    if skillEffectCalcParam.skillRange == nil then
        skillEffectCalcParam.skillRange = {skillEffectCalcParam.gridPos}
    end

    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    local attackPos = skillEffectCalcParam.attackPos
    local gridPos = skillEffectCalcParam.gridPos
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService

    local nTotalDamage, listDamageInfo =
        effectCalcSvc:ComputeSkillDamage(
        attacker,
        attackPos,
        defender,
        gridPos,
        skillEffectCalcParam.skillID,
        skillDamageParam,
        SkillEffectType.Damage,
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

    local skillResultList = {}
    table.insert(skillResultList, skillResult)

    return skillResultList
end
