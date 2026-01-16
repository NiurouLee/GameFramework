--[[
    DamageBasedOnPickUpRect = 92, --根据施法者坐标和点选位置的矩形范围，计算伤害(渡 主动技)
]]
require("calc_base")

---@class SkillEffectCalc_DamageBasedOnPickUpRect: SkillEffectCalc_Base
_class("SkillEffectCalc_DamageBasedOnPickUpRect", SkillEffectCalc_Base)
SkillEffectCalc_DamageBasedOnPickUpRect = SkillEffectCalc_DamageBasedOnPickUpRect

function SkillEffectCalc_DamageBasedOnPickUpRect:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageBasedOnPickUpRect:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}
    ---@type SkillDamageBasedOnPickUpRectEffectParam
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
    --根据点选的矩形范围计算伤害系数
    local rectX = {}
    local rectY = {}
    for k, pos in ipairs(skillEffectCalcParam.skillRange) do
        if not table.intable(rectX, pos.x) then
            table.insert(rectX, pos.x)
        end
        if not table.intable(rectY, pos.y) then
            table.insert(rectY, pos.y)
        end
    end
    --设置技能的范围长和宽
    skillEffectParam:SetSkillRangeRectParam(table.count(rectX), table.count(rectY))

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
function SkillEffectCalc_DamageBasedOnPickUpRect:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillDamageBasedOnPickUpRectEffectParam
    local skillDamageParam = skillEffectCalcParam.skillEffectParam

    ---@type Entity
    local defender = self._world:GetEntityByID(defenderEntityID)
    if defender == nil then
        Log.notice("CalculationForeachTarget defender is null ", defenderEntityID)
        ---由于每个效果会有自己的范围数据，所以这里还是需要返回一个空的result，给后边的表现使用
        local skillResult = self._skillEffectService:NewSkillDamageEffectResult(nil, -1, 0, nil, nil) ---伤害这里返回的TargetID == -1，非常坑�?
        return {skillResult}
    end

    if skillEffectCalcParam.skillRange == nil then
        skillEffectCalcParam.skillRange = {skillEffectCalcParam.gridPos}
    end

    ---@type Entity
    local attacker = self._world:GetEntityByID(skillEffectCalcParam.casterEntityID)
    local attackPos = skillEffectCalcParam.attackPos
    -- local gridPos = skillEffectCalcParam.gridPos
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local skillResultList = {}

    --怪物有一个格子在范围内就攻击一次
    local area = defender:BodyArea():GetArea()
    local locationPos = defender:GridLocation():GetGridPos()
    for i, bodyArea in ipairs(area) do
        local workPos = locationPos + bodyArea
        if table.intable(skillEffectCalcParam.skillRange, workPos) then
            local gridPos = workPos
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

            table.insert(skillResultList, skillResult)
        end
    end

    return skillResultList
end
