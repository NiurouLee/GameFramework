require("calc_damage")

_class("SkillEffectCalc_DynamicCenterDamage", SkillEffectCalc_Damage)
---@class SkillEffectCalc_DynamicCenterDamage : SkillEffectCalc_Damage
SkillEffectCalc_DynamicCenterDamage = SkillEffectCalc_DynamicCenterDamage

---@return number[], SkillScopeResult
function SkillEffectCalc_DynamicCenterDamage:SelectCenter(casterEntity, effectParam, centerPos, skillID)
    -- find real damage scope center
    local centerScopeType = effectParam:GetCenterScopeType()
    local centerScopeParam = effectParam:GetCenterScopeParam()  -- parsed by ctor

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCal = SkillScopeCalculator:New(utilScopeSvc)
    local centerScope = scopeCal:ComputeScopeRange(
            centerScopeType,
            centerScopeParam,
            centerPos,
            casterEntity:BodyArea():GetArea(),
            casterEntity:GetGridDirection(),
            SkillTargetType.MonsterTrap,
            casterEntity:GetGridPosition(),
            casterEntity
    )
    ---@type SkillScopeTargetSelector
    local selector = SkillScopeTargetSelector:New(self._world)
    local tTargetID = selector:DoSelectSkillTarget(casterEntity, SkillTargetType.MonsterTrap, centerScope)

    -- no center monster candidate at all
    if #tTargetID == 0 or table.icontains(tTargetID, -1) then
        return {}, SkillScopeResult:New(SkillScopeType.None, Vector2.zero, {}, {})
    end

    return tTargetID, centerScope
end

---@param skillEffectCalcParam SkillEffectCalcParam
function SkillEffectCalc_DynamicCenterDamage:DoSkillEffectCalculator(skillEffectCalcParam)
    ---@type SkillEffectParam_DynamicCenterDamage
    local effectParam = skillEffectCalcParam:GetSkillEffectParam()

    local casterEntityID = skillEffectCalcParam:GetCasterEntityID()
    local casterEntity = self._world:GetEntityByID(casterEntityID)

    local tTargetID, centerScope = self:SelectCenter(casterEntity, effectParam, skillEffectCalcParam:GetCenterPos(), skillEffectCalcParam:GetSkillID())

    if not centerScope then
        return {}
    end

    local centerScopeAttackRange = centerScope:GetAttackRange() or {} --有些范围返回出来这个会是nil

    local casterPos = casterEntity:GetGridPosition()
    local candidates = {}
    local trapCandidates = {}
    for _, eid in ipairs(tTargetID) do
        local e = self._world:GetEntityByID(eid)
        local gridPos = e:GetGridPosition()
        local nearestGrid = gridPos
        local nearestDistance = math.abs(casterPos.x - gridPos.x) + math.abs(casterPos.y - gridPos.y)
        local bodyArea = e:BodyArea():GetArea()
        if #bodyArea > 1 then
            for i = 2, #bodyArea do
                local v2 = bodyArea[i] + gridPos
                -- 多格怪物存在部分身位在中心范围外的情况，只有center范围内才参与计算
                if table.Vector2Include(centerScopeAttackRange, v2) then
                    local dis = math.abs(casterPos.x - v2.x) + math.abs(casterPos.y - v2.y)
                    if dis < nearestDistance then
                        nearestDistance = dis
                        nearestGrid = v2
                    end
                end
            end
        end

        local isTrap = e:HasTrap()
        local data = {eid = eid, v2 = nearestGrid, distance = nearestDistance}
        if isTrap then
            table.insert(trapCandidates, data)
        else
            table.insert(candidates, data)
        end
    end

    --如果没有怪物，从机关中以相同规则选择中心
    if #candidates == 0 then
        if #trapCandidates ~= 0 then
            candidates = trapCandidates
        else
            return {}
        end
    end

    --只选距离最近的单位
    local nearestCandidates = {}
    local dis = candidates[1].distance
    for _, data in ipairs(candidates) do
        if dis == data.distance then
            table.insert(nearestCandidates, data)
        elseif dis > data.distance then
            dis = data.distance
            nearestCandidates = {}
            table.insert(nearestCandidates, data)
        end
    end

    local finalCenterEntity = self._world:GetEntityByID(nearestCandidates[1].eid)
    local finalCenterPos = nearestCandidates[1].v2
    local hpPercent = 0

    --距离相同时选择血量最高的
    if (#nearestCandidates > 1) then
        for _, data in ipairs(nearestCandidates) do
            local eid = data.eid
            local e = self._world:GetEntityByID(eid)
            local attr = e:Attributes()
            local hp = attr:GetCurrentHP()
            local maxHP = attr:CalcMaxHp()
            local pct = hp / maxHP
            if pct > hpPercent then
                finalCenterEntity = e
                finalCenterPos = data.v2
                hpPercent = pct
            end
        end
    end

    -- calculate real damage scope
    ---@type SkillConfigData
    local skillConfigData = self._world:GetService("Config"):GetSkillConfigData(skillEffectCalcParam:GetSkillID(), casterEntity)
    local damageScopeType = skillConfigData:GetSkillScopeType()
    local damageScopeParam = skillConfigData:GetSkillScopeParam()

    ---@type UtilScopeCalcServiceShare
    local utilScopeSvc = self._world:GetService("UtilScopeCalc")
    ---@type SkillScopeCalculator
    local scopeCal = SkillScopeCalculator:New(utilScopeSvc)
    local damageScope = scopeCal:ComputeScopeRange(
        damageScopeType,
        damageScopeParam,
        finalCenterPos,
        {Vector2.zero},
        finalCenterEntity:GetGridDirection(),
        skillConfigData:GetSkillTargetType(),
        finalCenterPos,
        finalCenterEntity
    )

    ---@type SkillScopeTargetSelector
    local selector = SkillScopeTargetSelector:New(self._world)
    local targetIDs = selector:DoSelectSkillTarget(
        casterEntity,
        skillConfigData:GetSkillTargetType(),
        damageScope,
        skillEffectCalcParam:GetSkillID(),
        skillConfigData:GetSkillTargetTypeParam()
    )

    local damageResults = {}

    local utilData = self._world:GetService("UtilData")
    local targets = {}
    for _, id in ipairs(targetIDs) do
        if not table.icontains(targets, id) then
            table.insert(targets, id)
        end
    end

    local attackRange = damageScope:GetAttackRange() or {}
    for _, id in ipairs(targets) do
        local e = self._world:GetEntityByID(id)
        local gridPos = e:GetGridPosition()
        local bodyArea = e:BodyArea():GetArea() or {Vector2.zero}
        for _, v2Body in ipairs(bodyArea) do
            local v2 = gridPos + v2Body
            if table.Vector2Include(attackRange, v2) then
                local calcParam = SkillEffectCalcParam:New(
                        skillEffectCalcParam.casterEntityID,
                        {e:GetID()},
                        skillEffectCalcParam.skillEffectParam, -- skillEffectParam is a table so DO NOT MODIFY IT
                        skillEffectCalcParam.skillID,
                        damageScope:GetAttackRange(),
                        skillEffectCalcParam.attackPos,
                        v2,
                        skillEffectCalcParam.centerPos,
                        damageScope:GetWholeGridRange()
                )
                local r = SkillEffectCalc_DynamicCenterDamage.super.DoSkillEffectCalculator(self, calcParam)
                if r and #r > 0 then
                    table.appendArray(damageResults, r)
                end
            end
        end
    end

    local result = SkillEffectResult_DynamicCenterDamage:New(damageScope, damageResults)

    return {result}
end
