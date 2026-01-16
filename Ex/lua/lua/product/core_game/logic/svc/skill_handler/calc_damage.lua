--[[
    Damage = 1, --普通伤害
]]
require("calc_base")

_class("SkillEffectCalc_Damage", SkillEffectCalc_Base)
---@class SkillEffectCalc_Damage: SkillEffectCalc_Base
---@field New fun(MainWorld):SkillEffectCalc_Damage
SkillEffectCalc_Damage = SkillEffectCalc_Damage

function SkillEffectCalc_Damage:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_Damage:DoSkillEffectCalculator(skillEffectCalcParam)
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
function SkillEffectCalc_Damage:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillDamageEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam
    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)

        local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, damageStageIndex) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end

    local nTargetType = skillDamageParam:GetTargetType()
    if not PieceBlockData.IsEnumMatch(defender, nTargetType, nil) then
        return
    end

    if skillEffectCalcParam.skillRange == nil then
        skillEffectCalcParam.skillRange = {skillEffectCalcParam.gridPos}
    end

    ---@type FormulaService
    local formulaService = self._world:GetService("Formula")
    local attackPos = skillEffectCalcParam.attackPos
    local gridPos = skillEffectCalcParam.gridPos
    local skillResultList = {}

    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    
    local damageIncreaseBuffEffectType = skillDamageParam:GetDamageIncreaseBuffEffectType()
    local damageIncreaseMul = skillDamageParam:GetDamageIncreaseMul()

    if damageIncreaseBuffEffectType and damageIncreaseMul then
        ---@type SkillContextComponent
        local cSkillContext = attacker:SkillContext()
        cSkillContext:SetDamagePctIncreaseBuffEffectType(damageIncreaseBuffEffectType)
        cSkillContext:SetDamagePctIncreaseMul(damageIncreaseMul)
    end

    --先蛇用的最近点
    if skillDamageParam:GetNearPoint() > 0 then
        local listBodyPos = defender:GetCoverAreaList()
        local sortPosList = SortedArray:New(Algorithm.COMPARE_CUSTOM, AiSortByDistance._ComparerByNear)
        sortPosList:AllowDuplicate()
        for keyIndex, areaPos in ipairs(listBodyPos) do
            local bIsInRange = false
            if skillEffectCalcParam.skillRange[1]._className == nil then ---二维数组
                for _, skillRangePos in ipairs(skillEffectCalcParam.skillRange) do
                    bIsInRange = true
                    break
                end
            else
                if table.icontains(skillEffectCalcParam.skillRange, areaPos) then
                    bIsInRange = true
                end
            end
            if bIsInRange then
                AINewNode.InsertSortedArray(sortPosList, attackPos, areaPos, keyIndex)
            end
        end
        -- ---一个目标只有一个攻击点：选择距离攻击发起者最近的坐标
        -- if sortPosList:Size() > 0 then
        --     gridPos = sortPosList:GetAt(1):GetPosData()
        -- end

        --如果攻击范围的点 不是最近的点则返回不计算
        local nearPointGrid = sortPosList:GetAt(1):GetPosData()
        if gridPos.x ~= nearPointGrid.x or gridPos.y ~= nearPointGrid.y then
            return
        end
    end
    local damageTimes = skillDamageParam:GetDamageTimes()
    for i = 1, damageTimes do
        local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

        local ignoreShield = skillDamageParam:IsIgnoreShield()

        local nTotalDamage, listDamageInfo =
            effectCalcSvc:ComputeSkillDamage(
            attacker,
            attackPos,
            defender,
            gridPos,
            skillEffectCalcParam.skillID,
            skillDamageParam,
            SkillEffectType.Damage,
            damageStageIndex,
            ignoreShield,
            nil,
            skillEffectCalcParam:GetDamageGridPos()
        )
        --Log.fatal("Damage:",nTotalDamage," Pos:",gridPos," skillID:",skillEffectCalcParam.skillID," DamageStageIndex:",damageStageIndex)
        local skillResult =
            effectCalcSvc:NewSkillDamageEffectResult(
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
