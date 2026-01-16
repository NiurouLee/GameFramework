--[[
    MultipleDamageWithBuffLayer = 119, --根据施法者身上指定buff的层数，造成多次伤害
]]
---@class SkillEffectCalc_MultipleDamageWithBuffLayer: Object
_class("SkillEffectCalc_MultipleDamageWithBuffLayer", Object)
SkillEffectCalc_MultipleDamageWithBuffLayer = SkillEffectCalc_MultipleDamageWithBuffLayer

function SkillEffectCalc_MultipleDamageWithBuffLayer:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_MultipleDamageWithBuffLayer:DoSkillEffectCalculator(skillEffectCalcParam)
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
function SkillEffectCalc_MultipleDamageWithBuffLayer:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillEffectParamMultipleDamageWithBuffLayer
    local skillDamageParam = skillEffectCalcParam.skillEffectParam

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)

    --目标层数  决定了有多少次伤害结果
    ---@type BuffLogicService
    local svc = self._world:GetService("BuffLogic")
    local layerCount = svc:GetBuffLayer(attacker, skillDamageParam:GetBuffEffectType())

    if defender == nil or layerCount == 0 then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end

    local attackPos = skillEffectCalcParam.attackPos
    local gridPos = skillEffectCalcParam.gridPos
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    local skillResultList = {}
    for i = 1, layerCount do
        local nTotalDamage, listDamageInfo =
            self._skillEffectService:ComputeSkillDamage(
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
            self._skillEffectService:NewSkillDamageEffectResult(
            gridPos,
            defenderEntityID,
            nTotalDamage,
            listDamageInfo,
            damageStageIndex
        )

        table.insert(skillResultList, skillResult)
    end

    return skillResultList
end
