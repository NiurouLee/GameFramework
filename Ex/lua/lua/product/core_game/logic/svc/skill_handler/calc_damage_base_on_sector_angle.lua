--[[
    DamageBasedOnSectorAngle = 128,--在选择的扇形范围内，根据与主方向的夹角计算伤害
]]
require("calc_base")

---@class SkillEffectCalc_DamageBasedOnSectorAngle: SkillEffectCalc_Base
_class("SkillEffectCalc_DamageBasedOnSectorAngle", SkillEffectCalc_Base)
SkillEffectCalc_DamageBasedOnSectorAngle = SkillEffectCalc_DamageBasedOnSectorAngle

function SkillEffectCalc_DamageBasedOnSectorAngle:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DamageBasedOnSectorAngle:DoSkillEffectCalculator(skillEffectCalcParam)
    local results = {}
    ---@type SkillDamageBasedOnPickUpRectEffectParam
    local skillEffectParam = skillEffectCalcParam.skillEffectParam
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
function SkillEffectCalc_DamageBasedOnSectorAngle:_CalculateSingleTarget(skillEffectCalcParam, defenderEntityID)
    ---@type SkillEffectParam_DamageBasedOnSectorAngle
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
    local damageStageIndex = skillDamageParam:GetSkillEffectDamageStageIndex()


    --怪物有一个格子在范围内就攻击一次
    local area = defender:BodyArea():GetArea()
    local locationPos = defender:GridLocation():GetGridPos()

    

    ---@type SkillEffectCalcService
    local effectCalcSvc = self._skillEffectService
    local skillResultList = {}
    
    for i, bodyArea in ipairs(area) do
        local workPos = locationPos + bodyArea

        local damageRate = self:_CalculateAngleDamageRate(attackPos,workPos,skillEffectCalcParam)
        skillDamageParam:SetAngleDamageRate(damageRate)

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
function SkillEffectCalc_DamageBasedOnSectorAngle:_CalculateAngleDamageRate(casterPos,targetPos,skillEffectCalcParam)
    local centerPosVec = skillEffectCalcParam:GetCenterPos()
    if #centerPosVec > 1 then
        local selPos = centerPosVec[1]
        local mainDir = selPos - casterPos
        local targetDir = targetPos - casterPos
        local diffAngle = Vector2.Angle(mainDir,targetDir)
        diffAngle = math.floor(diffAngle + 0.5) --四舍五入取整 精度问题
        ---@type SkillEffectParam_DamageBasedOnSectorAngle
        local skillDamageParam = skillEffectCalcParam.skillEffectParam
        local maxAngle = skillDamageParam:GetMaxAngle()
        local minRate = skillDamageParam:GetMinDamageRate()
        if maxAngle > 0 then
            local decRateRange = 1 - minRate
            local resRate = 1 - ((diffAngle / maxAngle) * decRateRange)
            return resRate
        end
    end
    return 1
end