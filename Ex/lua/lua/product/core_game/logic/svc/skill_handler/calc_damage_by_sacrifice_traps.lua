--[[
    MonsterMoveLongestGrid = 156, --怪物选择一条最长的路线，可支持多种选法
]]

_class("SkillEffectCalc_DamageBySacrificeTraps", Object)
---@class SkillEffectCalc_DamageBySacrificeTraps: Object
SkillEffectCalc_DamageBySacrificeTraps = SkillEffectCalc_DamageBySacrificeTraps

function SkillEffectCalc_DamageBySacrificeTraps:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")

end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageBySacrificeTraps:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type Entity
    local casterEntity = self._world:GetEntityByID(skillEffectCalcParam:GetCasterEntityID())
    local targetIDList = skillEffectCalcParam:GetTargetEntityIDs()
    ---@type SkillEffectDamageBySacrificeTrapsParam
    local param = skillEffectCalcParam.skillEffectParam
    ---@type SkillEffectResultContainer
    local routineComponent = casterEntity:SkillContext():GetResultContainer()
    ---@type table<number, SkillEffectResultSacrificeTraps>
    local resultsArray = routineComponent:GetEffectResultsAsArray(SkillEffectType.SacrificeTraps)
    if not resultsArray then
        return { SkillEffectDamageBySacrificeTraps:New() }
    end
    local needAttackTrapIDs = param:GetTrapID()
    local attackCount = 1
    for i, result in ipairs(resultsArray) do
        local trapIDs = result:GetTrapIDs()
        for i, entityID in ipairs(trapIDs) do
            ---@type Entity
            local trapEntity = self._world:GetEntityByID(entityID)
            if trapEntity:HasTrap() and  needAttackTrapIDs[trapEntity:Trap():GetTrapID()] then
                attackCount = attackCount +1
            end
        end
    end

    local targetID = false
    if table.count(targetIDList) >= 1 then
        targetID = targetIDList[1]
    end
    if not targetID or targetID == -1 then
        Log.fatal("Need Target SkillID", skillEffectCalcParam:GetSkillID())
    end
    local resultArray = {}
    ---@type Entity
    local defender = self._world:GetEntityByID(targetID)
    ---@type TriggerService
    local triggerService = self._world:GetService("Trigger")
    triggerService:Notify(NTEffect158AttackBegin:New(casterEntity))
    local defenderPos = defender:GetGridPosition()
    local attackerPos = casterEntity:GetGridPosition()
    ---@type SkillDamageEffectParam
    local skillDamageParam = param

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    for i = 1, attackCount do
        local nTotalDamage, listDamageInfo = effectCalcSvc:ComputeSkillDamage(
                casterEntity,
                attackerPos,
                defender,
                defenderPos,
                skillEffectCalcParam.skillID,
                skillDamageParam,
                SkillEffectType.DamageBySacrificeTraps,
                damageStageIndex
        )

        local skillResult = effectCalcSvc:NewSkillDamageEffectResult(
                defenderPos,
                targetID,
                nTotalDamage,
                listDamageInfo,
                damageStageIndex
        )
        table.insert(resultArray, skillResult)
    end
    triggerService:Notify(NTEffect158AttackEnd:New(casterEntity))
    return resultArray
end

