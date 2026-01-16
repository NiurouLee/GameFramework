--[[
    NightKingTeleportPathDamage = 204, -- 夜王专属 在瞬移的每段路径（目标是）上计算范围，造成伤害，瞬移终点
]]
---@class NightKingTeleportPathDamageCalculator: Object
_class("NightKingTeleportPathDamageCalculator", Object)
NightKingTeleportPathDamageCalculator = NightKingTeleportPathDamageCalculator

function NightKingTeleportPathDamageCalculator:Constructor(world)
    ---@type MainWorld
    self._world = world

    ---@type SkillEffectCalcService
    self._skillEffectService = self._world:GetService("SkillEffectCalc")
end

---@param casterEntity Entity
---@param skillEffectCalcParam SkillEffectParamNightKingTeleportPathDamage
---@param finalScopeFilterParam SkillScopeFilterParam
---@return table
function NightKingTeleportPathDamageCalculator:Calculate(casterEntity, skillEffectCalcParam, finalScopeFilterParam)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    ---
    ---@type SkillEffectResult_Teleport
    local teleportResult = nil
    ---@type SkillEffectResult_Teleport[]
    local skillEffectResult_Teleport_Array = skillEffectResultContainer:GetEffectResultsAsArray(SkillEffectType.Teleport)
    if #skillEffectResult_Teleport_Array > 0 then
        teleportResult = skillEffectResult_Teleport_Array[1]
    end
    if not teleportResult then
        return
    end
    local telPath = teleportResult:GetRenderTeleportPath()
    if #telPath > 1 then--表示有经过机关
    elseif #telPath == 1 then--没有机关
    else
        return
    end
    local startPos = teleportResult:GetPosOld()--瞬移起点
    local finishPos = teleportResult:GetPosNew()--瞬移终点

    ---@type SkillDamageEffectResult[]
    local results = {}
    local renderTelLastPos = startPos
    --对每段向机关的瞬移（表现上），对沿途造成伤害
    for index, tarPos in ipairs(telPath) do
        if index ~= #telPath then
            --向机关瞬移（表现上）
            local damageStageIndex = index
            local damageResults = self:_CalcTeleportToTrapDamage(casterEntity,skillEffectCalcParam,renderTelLastPos,tarPos,damageStageIndex)
            table.appendArray(results,damageResults)
        else
            local damageStageIndex = index
            local damageResults = self:_CalcTeleportToFinalDamage(casterEntity,skillEffectCalcParam,renderTelLastPos,tarPos,damageStageIndex)
            table.appendArray(results,damageResults)
        end
        renderTelLastPos = tarPos
    end
    for _, v in ipairs(results) do
        skillEffectResultContainer:AddEffectResult(v)
    end
    return results
end
---@param casterEntity Entity
---@param skillEffectCalcParam SkillEffectParamNightKingTeleportPathDamage
function NightKingTeleportPathDamageCalculator:_CalcTeleportToTrapDamage(casterEntity, skillEffectCalcParam,fromPos,toPos,damageStageIndex)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()

    local casterPos = casterEntity:GetGridPosition()
    local scopeType = skillEffectCalcParam:GetPathDamageScopeType()
    local scopeParam = skillEffectCalcParam:GetPathDamageScopeParam()
    local targetType = skillEffectCalcParam:GetPathDamageTargetType()
    local scopeResult =
        scopeCalc:ComputeScopeRange(
        scopeType,
        scopeParam,
        {fromPos,toPos},
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        targetType,
        casterEntity:GetGridPosition()
    )
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, scopeResult)
    local results = {}
    for index, targetID in ipairs(targetIDList) do
        local targetEntity = self._world:GetEntityByID(targetID)
        --对目标执行伤害计算
        ---@type SkillEffectCalcParam
        local damageCalcParam =
            SkillEffectCalcParam:New(
                casterEntity:GetID(),
                {targetID},
                skillEffectCalcParam,--damageEffectParam
                skillID,
                scopeResult:GetAttackRange(),
                toPos,
                targetEntity:GetGridPosition()
        )
        ---@type SkillEffectCalc_Damage
        local skillEffectCalc = SkillEffectCalc_Damage:New(self._world)
        ---@type SkillDamageEffectResult[]
        local result = skillEffectCalc:DoSkillEffectCalculator(damageCalcParam)
        for index, dmgResult in ipairs(result) do
            dmgResult._damageStageIndex = damageStageIndex
        end
        table.appendArray(results,result)
    end
    return results
end
---@param casterEntity Entity
---@param skillEffectCalcParam SkillEffectParamNightKingTeleportPathDamage
function NightKingTeleportPathDamageCalculator:_CalcTeleportToFinalDamage(casterEntity, skillEffectCalcParam,fromPos,toPos,damageStageIndex)
    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCalc = utilScopeSvc:GetSkillScopeCalc()

    local casterPos = casterEntity:GetGridPosition()
    local scopeType = skillEffectCalcParam:GetFinalDamageScopeType()
    local scopeParam = skillEffectCalcParam:GetFinalDamageScopeParam()
    local targetType = skillEffectCalcParam:GetFinalDamageTargetType()
    local scopeResult =
        scopeCalc:ComputeScopeRange(
        scopeType,
        scopeParam,
        toPos,
        casterEntity:BodyArea():GetArea(),
        casterEntity:GetGridDirection(),
        targetType,
        casterPos
    )
    local targetIDList = utilScopeSvc:SelectSkillTarget(casterEntity, targetType, scopeResult)
    ---@type SkillEffectResultContainer
    local skillEffectResultContainer = casterEntity:SkillContext():GetResultContainer()
    local skillID = skillEffectResultContainer:GetSkillID()
    local results = {}
    for index, targetID in ipairs(targetIDList) do
        local targetEntity = self._world:GetEntityByID(targetID)
        --对目标执行伤害计算
        ---@type SkillEffectCalcParam
        local damageCalcParam =
            SkillEffectCalcParam:New(
                casterEntity:GetID(),
                {targetID},
                skillEffectCalcParam,--damageEffectParam
                skillID,
                scopeResult:GetAttackRange(),
                toPos,
                targetEntity:GetGridPosition()
        )
        ---@type SkillEffectCalc_Damage
        local skillEffectCalc = SkillEffectCalc_Damage:New(self._world)
        ---@type SkillDamageEffectResult[]
        local result = skillEffectCalc:DoSkillEffectCalculator(damageCalcParam)
        for index, dmgResult in ipairs(result) do
            dmgResult._damageStageIndex = damageStageIndex
        end
        table.appendArray(results,result)
    end
    return results
end