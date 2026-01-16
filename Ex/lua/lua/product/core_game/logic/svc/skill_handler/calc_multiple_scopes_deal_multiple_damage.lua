--[[
    MultipleScopesDealMultipleDamage = 99, --同一个目标在被技能范围覆盖多次，造成多次伤害
]]
---@class SkillEffectCalc_MultipleScopesDealMultipleDamage: Object
_class("SkillEffectCalc_MultipleScopesDealMultipleDamage", Object)
SkillEffectCalc_MultipleScopesDealMultipleDamage = SkillEffectCalc_MultipleScopesDealMultipleDamage

function SkillEffectCalc_MultipleScopesDealMultipleDamage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MultipleScopesDealMultipleDamage:DoSkillEffectCalculator(skillEffectCalcParam)
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

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MultipleScopesDealMultipleDamage:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillMultipleScopesDealMultipleDamageEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end

    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local attackPos = skillEffectCalcParam.attackPos
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    local bodyAreaPosList = {}
    local bodyArea = defender:BodyArea():GetArea()
    local cneterPos = defender:GetGridPosition()
    for _, area in ipairs(bodyArea) do
        local workPos = area + cneterPos
        table.insert(bodyAreaPosList, workPos)
    end

    --目标身形在技能范围内出现的次数  决定了有多少次伤害结果
    local gridPosList = {}
    for i = 1, #skillEffectCalcParam.skillRange do
        local skillRangePos = skillEffectCalcParam.skillRange[i]
        if table.intable(bodyAreaPosList, skillRangePos) then
            table.insert(gridPosList, skillRangePos)
        end
    end

    local curSkillDamageIndex = 1

    local skillResultList = {}
    for i = 1, #gridPosList do
        local gridPos = gridPosList[i]

        local nTotalDamage, listDamageInfo =
            self._skillEffectService:ComputeSkillDamage(
            attacker,
            attackPos,
            defender,
            gridPos,
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.Damage,
            damageStageIndex,
            nil,
            curSkillDamageIndex,
            gridPos
        )

        local damageInfo = listDamageInfo[1]
        if damageInfo then
            damageInfo:SetCurSkillDamageIndex(curSkillDamageIndex)
        end

        local skillResult =
            self._skillEffectService:NewSkillDamageEffectResult(
            gridPos,
            defenderEntityID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
        )

        table.insert(skillResultList, skillResult)
        curSkillDamageIndex = curSkillDamageIndex + 1
    end

    return skillResultList
end
